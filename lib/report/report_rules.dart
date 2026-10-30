// Kural motoru: girilen değerlerden UYGUN / UYGUN DEĞİL önerisi ve eksik alan listesi üretir.
// Öneriler teknisyen tarafından her zaman değiştirilebilir (resultOverride).
// Kural kaynakları rapor şablonundaki "Ağır kusur tanımları" ile aynıdır.

import 'report_models.dart';
import 'report_template.dart';

/// Türkçe yazımlı sayıyı ayrıştırır: "0,28" -> 0.28, "4.000" -> 4000, "-" / "" -> null.
double? parseTrNumber(String raw) {
  var s = raw.trim();
  if (s.isEmpty || s == '-') return null;
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) {
    s = s.replaceAll('.', '');
  }
  final m = RegExp(r'-?\d+(\.\d+)?').firstMatch(s);
  return m == null ? null : double.tryParse(m.group(0)!);
}

/// Kesit yazımından tek iletken kesitini çıkarır: "1X3X35" -> 35, "1X2,5" -> 2.5, "3x70+35" -> 70.
double? parseSectionMm2(String raw) {
  final s = raw.trim().split('+').first;
  if (s.isEmpty || s == '-') return null;
  final parts = s.split(RegExp(r'[xX×*]'));
  return parseTrNumber(parts.last);
}

/// IEC 60364-5-54 Tablo 54.2 / ETTY Çizelge 8: aynı malzemeden PE için asgari kesit.
double minPeSection(double phase) {
  if (phase <= 16) return phase;
  if (phase <= 35) return 16;
  return phase / 2;
}

bool isFilled(String v) => v.trim().isNotEmpty;

enum IssueLevel { fail, warn }

class RuleIssue {
  final IssueLevel level;
  final String message;
  const RuleIssue(this.level, this.message);
}

class CircuitCheck {
  final List<RuleIssue> issues;
  final Evaluation? suggested;
  const CircuitCheck(this.issues, this.suggested);
}

String _fmt(double v) {
  final s = v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  return s.replaceAll('.', ',');
}

CircuitCheck checkCircuit(Circuit c, {required SiteProfile profile, required String panelIkKa}) {
  final issues = <RuleIssue>[];
  final ib = parseTrNumber(c.ibA);
  final inA = parseTrNumber(c.inA);
  final iz = parseTrNumber(c.izA);

  if (ib != null && inA != null && ib > inA) {
    issues.add(RuleIssue(IssueLevel.fail, 'Ib (${_fmt(ib)} A) > In (${_fmt(inA)} A): Ib ≤ In sağlanmıyor.'));
  }
  if (inA != null && iz != null && inA > iz) {
    issues.add(RuleIssue(IssueLevel.fail, 'In (${_fmt(inA)} A) > Iz (${_fmt(iz)} A): kablo korunmuyor (In ≤ Iz).'));
  }

  final icu = parseTrNumber(c.icuKa);
  final ik = parseTrNumber(panelIkKa);
  if (icu != null && ik != null && icu < ik) {
    issues.add(RuleIssue(IssueLevel.fail, 'Icu (${_fmt(icu)} kA) < Ik (${_fmt(ik)} kA): kesme kapasitesi yetersiz.'));
  }

  final idn = parseTrNumber(c.idnMa);
  if (idn != null) {
    if (idn > profile.rcdRatedMa) {
      issues.add(RuleIssue(IssueLevel.fail, 'RCD açma akımı ${_fmt(idn)} mA > anma ${_fmt(profile.rcdRatedMa)} mA.'));
    } else if (idn < profile.rcdRatedMa / 2) {
      issues.add(RuleIssue(IssueLevel.warn,
          'RCD ${_fmt(idn)} mA ile anma değerinin yarısından önce açıyor; anma değerini kontrol edin.'));
    }
  }
  final td = parseTrNumber(c.tdMs);
  if (td != null && td > profile.rcdMaxMs) {
    issues.add(RuleIssue(IssueLevel.fail, 'RCD açma süresi ${_fmt(td)} ms > ${_fmt(profile.rcdMaxMs)} ms.'));
  }

  final phase = parseSectionMm2(c.phaseSection);
  final pe = parseSectionMm2(c.peSection);
  final n = parseSectionMm2(c.nSection);
  if (phase != null && pe != null && pe < minPeSection(phase)) {
    issues.add(RuleIssue(IssueLevel.fail,
        'PE kesiti ${_fmt(pe)} mm² < asgari ${_fmt(minPeSection(phase))} mm² (faz ${_fmt(phase)} mm²).'));
  }
  if (phase != null && n != null && n < phase) {
    issues.add(RuleIssue(IssueLevel.warn,
        'N kesiti (${_fmt(n)} mm²) fazdan (${_fmt(phase)} mm²) küçük: koruma N kesitine göre seçilmiş mi kontrol edin.'));
  }

  Evaluation? suggested;
  if (issues.any((i) => i.level == IssueLevel.fail)) {
    suggested = Evaluation.uygunDegil;
  } else if (ib != null && inA != null && iz != null) {
    suggested = Evaluation.uygun;
  }
  return CircuitCheck(issues, suggested);
}

Evaluation? circuitResult(Circuit c, {required SiteProfile profile, required String panelIkKa}) =>
    c.resultOverride ?? checkCircuit(c, profile: profile, panelIkKa: panelIkKa).suggested;

Evaluation? floorSuggested(FloorInsulation f, SiteProfile profile) {
  final r = parseTrNumber(f.resistanceKohm);
  if (r == null) return null;
  return r > profile.floorMinKohm ? Evaluation.uygun : Evaluation.uygunDegil;
}

Evaluation? floorResult(FloorInsulation f, SiteProfile profile) => f.resultOverride ?? floorSuggested(f, profile);

/// Herhangi bir kriter, devre veya zemin ölçümü UYGUN DEĞİL ise tesisat uygun değildir.
bool suggestedConclusion(PanelReport r, SiteProfile profile) {
  if (r.criteria.values.contains(Evaluation.uygunDegil)) return false;
  for (final c in r.circuits) {
    if (circuitResult(c, profile: profile, panelIkKa: r.ikKa) == Evaluation.uygunDegil) return false;
  }
  for (final f in r.floorInsulations) {
    if (floorResult(f, profile) == Evaluation.uygunDegil) return false;
  }
  return true;
}

bool conclusion(PanelReport r, SiteProfile profile) => r.conclusionOverride ?? suggestedConclusion(r, profile);

/// Raporun "tamamlandı" sayılması için eksik kalan alanlar.
/// Bilinmeyen değer için "-" yazılması alanı doldurulmuş sayar; boş alan eksiktir.
List<String> missingFields(PanelReport r) {
  final missing = <String>[];
  if (!isFilled(r.panelName)) missing.add('Pano adı');
  if (!isFilled(r.reportNo)) missing.add('Rapor numarası');
  if (r.start == null) missing.add('Kontrol başlangıç tarihi/saati');
  if (r.end == null) missing.add('Kontrol bitiş tarihi/saati');

  final unevaluated = ReportTemplate.allCriteria.where((c) => !r.criteria.containsKey(c.id)).length;
  if (unevaluated > 0) missing.add('Değerlendirilmemiş kontrol kriteri: $unevaluated');

  final measurements = {
    'Faz-nötr çevrim empedansı (ZLN)': r.zlnOhm,
    'Faz-toprak çevrim empedansı (Zx)': r.zxOhm,
    'F-F gerilimi': r.vff,
    'L-N gerilimi': r.vln,
    'N-PE gerilimi': r.vnpe,
    'Kısa devre akımı (Ik)': r.ikKa,
    'DKD tipi': r.spdType,
    'DKD dayanma akımı': r.spdKa,
  };
  measurements.forEach((label, v) {
    if (!isFilled(v)) missing.add(label);
  });

  if (r.circuits.isEmpty) {
    missing.add('Fonksiyon test tablosunda devre yok');
  }
  for (var i = 0; i < r.circuits.length; i++) {
    final c = r.circuits[i];
    final empty = [
      c.name,
      c.curve,
      c.poles,
      c.icuKa,
      c.inA,
      c.ibA,
      c.phaseSection,
      c.peSection,
      c.nSection,
      c.izA,
      c.idnMa,
      c.tdMs,
    ].where((v) => !isFilled(v)).length;
    if (empty > 0) {
      final name = isFilled(c.name) ? c.name : 'isimsiz';
      missing.add('Devre ${i + 1} ($name): $empty boş alan');
    }
  }

  if (r.floorInsulations.isEmpty) missing.add('Zemin izolasyonu ölçümü yok');
  for (var i = 0; i < r.floorInsulations.length; i++) {
    final f = r.floorInsulations[i];
    if (!isFilled(f.location) || !isFilled(f.resistanceKohm)) {
      missing.add('Zemin izolasyonu ${i + 1}: yer veya direnç boş');
    }
  }
  return missing;
}

String two(int v) => v.toString().padLeft(2, '0');

String formatDate(DateTime? d) => d == null ? '-' : '${two(d.day)}.${two(d.month)}.${d.year}';

String formatDateTime(DateTime? d) => d == null ? '-' : '${formatDate(d)} VE ${two(d.hour)}:${two(d.minute)}';

String orDash(String v) => isFilled(v) ? v.trim() : '-';
