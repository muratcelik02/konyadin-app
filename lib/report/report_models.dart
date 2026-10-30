// Periyodik kontrol raporu veri modeli.
// Görev (tesis + firma + cihazlar + yetkili) -> Pano raporları -> Devreler.
// Sayısal alanlar teknisyenin yazdığı haliyle (ör. "2,5", "1X3X35") saklanır; kurallar
// gerektiğinde ayrıştırır, PDF ise aynen basar. Boş alan raporda "-" olarak görünür.

enum Evaluation { uygun, uygunDegil, uygulanamaz }

extension EvaluationLabel on Evaluation {
  String get label {
    switch (this) {
      case Evaluation.uygun:
        return 'UYGUN';
      case Evaluation.uygunDegil:
        return 'UYGUN DEĞİL';
      case Evaluation.uygulanamaz:
        return 'UYGULANAMAZ';
    }
  }
}

Evaluation? _evalFromJson(dynamic v) {
  if (v is! String) return null;
  for (final e in Evaluation.values) {
    if (e.name == v) return e;
  }
  return null;
}

DateTime? _dateFromJson(dynamic v) => v is String ? DateTime.tryParse(v) : null;

Map<String, String> _stringMap(dynamic v) =>
    v is Map ? v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? '')) : <String, String>{};

class MeasuringDevice {
  String name;
  String calibrationDate;
  String validity;
  String serialNo;
  String calibrationNo;

  MeasuringDevice({
    this.name = '',
    this.calibrationDate = '',
    this.validity = '',
    this.serialNo = '',
    this.calibrationNo = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'calibrationDate': calibrationDate,
        'validity': validity,
        'serialNo': serialNo,
        'calibrationNo': calibrationNo,
      };

  factory MeasuringDevice.fromJson(Map<String, dynamic> j) => MeasuringDevice(
        name: j['name'] ?? '',
        calibrationDate: j['calibrationDate'] ?? '',
        validity: j['validity'] ?? '',
        serialNo: j['serialNo'] ?? '',
        calibrationNo: j['calibrationNo'] ?? '',
      );
}

/// Bir görevdeki tüm pano raporlarında ortak olan bilgiler (rapor bölüm 1-4 ve 11).
class SiteProfile {
  Map<String, String> texts;
  Map<String, List<String>> choices;
  List<MeasuringDevice> thermalDevices;
  List<MeasuringDevice> measuringDevices;

  String inspectorName;
  String inspectorProfession;
  String inspectorDiplomaNo;
  String inspectorEkipnetNo;

  String kontrolFirmasiEkli;
  String? logoPath;

  String reportNoPrefix;
  int nextReportNo;
  int minutesPerPanel;

  // Kural motoru ayarları
  double rcdRatedMa;
  double rcdMaxMs;
  double floorMinKohm;

  SiteProfile({
    Map<String, String>? texts,
    Map<String, List<String>>? choices,
    List<MeasuringDevice>? thermalDevices,
    List<MeasuringDevice>? measuringDevices,
    this.inspectorName = '',
    this.inspectorProfession = '',
    this.inspectorDiplomaNo = '',
    this.inspectorEkipnetNo = '',
    this.kontrolFirmasiEkli = '',
    this.logoPath,
    this.reportNoPrefix = 'Elk.',
    this.nextReportNo = 1,
    this.minutesPerPanel = 15,
    this.rcdRatedMa = 30,
    this.rcdMaxMs = 300,
    this.floorMinKohm = 50,
  })  : texts = texts ?? {},
        choices = choices ?? {},
        thermalDevices = thermalDevices ?? [MeasuringDevice(), MeasuringDevice()],
        measuringDevices = measuringDevices ?? [MeasuringDevice(), MeasuringDevice()];

  SiteProfile copy() => SiteProfile.fromJson(toJson());

  String text(String id) => texts[id] ?? '';
  List<String> choice(String id) => choices[id] ?? const [];

  Map<String, dynamic> toJson() => {
        'texts': texts,
        'choices': choices,
        'thermalDevices': thermalDevices.map((d) => d.toJson()).toList(),
        'measuringDevices': measuringDevices.map((d) => d.toJson()).toList(),
        'inspectorName': inspectorName,
        'inspectorProfession': inspectorProfession,
        'inspectorDiplomaNo': inspectorDiplomaNo,
        'inspectorEkipnetNo': inspectorEkipnetNo,
        'kontrolFirmasiEkli': kontrolFirmasiEkli,
        'logoPath': logoPath,
        'reportNoPrefix': reportNoPrefix,
        'nextReportNo': nextReportNo,
        'minutesPerPanel': minutesPerPanel,
        'rcdRatedMa': rcdRatedMa,
        'rcdMaxMs': rcdMaxMs,
        'floorMinKohm': floorMinKohm,
      };

  factory SiteProfile.fromJson(Map<String, dynamic> j) => SiteProfile(
        texts: _stringMap(j['texts']),
        choices: (j['choices'] as Map?)?.map(
              (k, v) => MapEntry(k.toString(), (v as List).map((e) => e.toString()).toList()),
            ) ??
            {},
        thermalDevices:
            (j['thermalDevices'] as List?)?.map((d) => MeasuringDevice.fromJson(Map<String, dynamic>.from(d))).toList(),
        measuringDevices: (j['measuringDevices'] as List?)
            ?.map((d) => MeasuringDevice.fromJson(Map<String, dynamic>.from(d)))
            .toList(),
        inspectorName: j['inspectorName'] ?? '',
        inspectorProfession: j['inspectorProfession'] ?? '',
        inspectorDiplomaNo: j['inspectorDiplomaNo'] ?? '',
        inspectorEkipnetNo: j['inspectorEkipnetNo'] ?? '',
        kontrolFirmasiEkli: j['kontrolFirmasiEkli'] ?? '',
        logoPath: j['logoPath'],
        reportNoPrefix: j['reportNoPrefix'] ?? 'Elk.',
        nextReportNo: (j['nextReportNo'] as num?)?.toInt() ?? 1,
        minutesPerPanel: (j['minutesPerPanel'] as num?)?.toInt() ?? 15,
        rcdRatedMa: (j['rcdRatedMa'] as num?)?.toDouble() ?? 30,
        rcdMaxMs: (j['rcdMaxMs'] as num?)?.toDouble() ?? 300,
        floorMinKohm: (j['floorMinKohm'] as num?)?.toDouble() ?? 50,
      );
}

/// Fonksiyon test tablosunun bir satırı.
class Circuit {
  String name;
  String curve;
  String poles;
  String icuKa;
  String inA;
  String ibA;
  String phaseSection;
  String peSection;
  String nSection;
  String izA;
  String idnMa;
  String tdMs;
  Evaluation? resultOverride;
  String note;

  Circuit({
    this.name = '',
    this.curve = '',
    this.poles = '',
    this.icuKa = '',
    this.inA = '',
    this.ibA = '',
    this.phaseSection = '',
    this.peSection = '',
    this.nSection = '',
    this.izA = '',
    this.idnMa = '',
    this.tdMs = '',
    this.resultOverride,
    this.note = '',
  });

  /// Sonraki devre için şablon: koruma ve kablo bilgileri kopyalanır,
  /// ölçümler (Ib, IΔ, TΔ) ve sonuç asla kopyalanmaz.
  Circuit copyAsTemplate() => Circuit(
        curve: curve,
        poles: poles,
        icuKa: icuKa,
        inA: inA,
        phaseSection: phaseSection,
        peSection: peSection,
        nSection: nSection,
        izA: izA,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'curve': curve,
        'poles': poles,
        'icuKa': icuKa,
        'inA': inA,
        'ibA': ibA,
        'phaseSection': phaseSection,
        'peSection': peSection,
        'nSection': nSection,
        'izA': izA,
        'idnMa': idnMa,
        'tdMs': tdMs,
        'resultOverride': resultOverride?.name,
        'note': note,
      };

  factory Circuit.fromJson(Map<String, dynamic> j) => Circuit(
        name: j['name'] ?? '',
        curve: j['curve'] ?? '',
        poles: j['poles'] ?? '',
        icuKa: j['icuKa'] ?? '',
        inA: j['inA'] ?? '',
        ibA: j['ibA'] ?? '',
        phaseSection: j['phaseSection'] ?? '',
        peSection: j['peSection'] ?? '',
        nSection: j['nSection'] ?? '',
        izA: j['izA'] ?? '',
        idnMa: j['idnMa'] ?? '',
        tdMs: j['tdMs'] ?? '',
        resultOverride: _evalFromJson(j['resultOverride']),
        note: j['note'] ?? '',
      );
}

class FloorInsulation {
  String location;
  String widthM;
  String lengthM;
  String resistanceKohm;
  Evaluation? resultOverride;

  FloorInsulation({
    this.location = '',
    this.widthM = '',
    this.lengthM = '',
    this.resistanceKohm = '',
    this.resultOverride,
  });

  Map<String, dynamic> toJson() => {
        'location': location,
        'widthM': widthM,
        'lengthM': lengthM,
        'resistanceKohm': resistanceKohm,
        'resultOverride': resultOverride?.name,
      };

  factory FloorInsulation.fromJson(Map<String, dynamic> j) => FloorInsulation(
        location: j['location'] ?? '',
        widthM: j['widthM'] ?? '',
        lengthM: j['lengthM'] ?? '',
        resistanceKohm: j['resistanceKohm'] ?? '',
        resultOverride: _evalFromJson(j['resultOverride']),
      );
}

/// Tek bir pano için rapor (bölüm 5-10).
class PanelReport {
  final String id;
  String panelName;
  String reportNo;
  DateTime? start;
  DateTime? end;
  DateTime? nextDate;
  DateTime? reportDate;

  Map<String, Evaluation> criteria;
  String thermalPhotoNo;
  String thermalPhotoDate;

  List<String> method;
  String zlnOhm;
  String zxOhm;
  String vff;
  String vln;
  String vnpe;
  String spdType;
  String ikKa;
  String spdKa;

  List<Circuit> circuits;
  List<FloorInsulation> floorInsulations;
  String defects;

  String? equipmentPhotoPath;
  String? thermalPhotoPath;

  /// null: sonuç kurallardan otomatik; true/false: teknisyenin kararı.
  bool? conclusionOverride;

  DateTime updatedAt;

  PanelReport({
    required this.id,
    this.panelName = '',
    this.reportNo = '',
    this.start,
    this.end,
    this.nextDate,
    this.reportDate,
    Map<String, Evaluation>? criteria,
    this.thermalPhotoNo = '',
    this.thermalPhotoDate = '',
    List<String>? method,
    this.zlnOhm = '',
    this.zxOhm = '',
    this.vff = '',
    this.vln = '',
    this.vnpe = '',
    this.spdType = '',
    this.ikKa = '',
    this.spdKa = '',
    List<Circuit>? circuits,
    List<FloorInsulation>? floorInsulations,
    this.defects = '',
    this.equipmentPhotoPath,
    this.thermalPhotoPath,
    this.conclusionOverride,
    DateTime? updatedAt,
  })  : criteria = criteria ?? {},
        method = method ?? ['ÇEVRİM EMPEDANSI'],
        circuits = circuits ?? [],
        floorInsulations = floorInsulations ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'panelName': panelName,
        'reportNo': reportNo,
        'start': start?.toIso8601String(),
        'end': end?.toIso8601String(),
        'nextDate': nextDate?.toIso8601String(),
        'reportDate': reportDate?.toIso8601String(),
        'criteria': criteria.map((k, v) => MapEntry(k, v.name)),
        'thermalPhotoNo': thermalPhotoNo,
        'thermalPhotoDate': thermalPhotoDate,
        'method': method,
        'zlnOhm': zlnOhm,
        'zxOhm': zxOhm,
        'vff': vff,
        'vln': vln,
        'vnpe': vnpe,
        'spdType': spdType,
        'ikKa': ikKa,
        'spdKa': spdKa,
        'circuits': circuits.map((c) => c.toJson()).toList(),
        'floorInsulations': floorInsulations.map((f) => f.toJson()).toList(),
        'defects': defects,
        'equipmentPhotoPath': equipmentPhotoPath,
        'thermalPhotoPath': thermalPhotoPath,
        'conclusionOverride': conclusionOverride,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PanelReport.fromJson(Map<String, dynamic> j) {
    final criteria = <String, Evaluation>{};
    (j['criteria'] as Map?)?.forEach((k, v) {
      final e = _evalFromJson(v);
      if (e != null) criteria[k.toString()] = e;
    });
    return PanelReport(
      id: j['id'],
      panelName: j['panelName'] ?? '',
      reportNo: j['reportNo'] ?? '',
      start: _dateFromJson(j['start']),
      end: _dateFromJson(j['end']),
      nextDate: _dateFromJson(j['nextDate']),
      reportDate: _dateFromJson(j['reportDate']),
      criteria: criteria,
      thermalPhotoNo: j['thermalPhotoNo'] ?? '',
      thermalPhotoDate: j['thermalPhotoDate'] ?? '',
      method: (j['method'] as List?)?.map((e) => e.toString()).toList(),
      zlnOhm: j['zlnOhm'] ?? '',
      zxOhm: j['zxOhm'] ?? '',
      vff: j['vff'] ?? '',
      vln: j['vln'] ?? '',
      vnpe: j['vnpe'] ?? '',
      spdType: j['spdType'] ?? '',
      ikKa: j['ikKa'] ?? '',
      spdKa: j['spdKa'] ?? '',
      circuits: (j['circuits'] as List?)?.map((c) => Circuit.fromJson(Map<String, dynamic>.from(c))).toList(),
      floorInsulations:
          (j['floorInsulations'] as List?)?.map((f) => FloorInsulation.fromJson(Map<String, dynamic>.from(f))).toList(),
      defects: j['defects'] ?? '',
      equipmentPhotoPath: j['equipmentPhotoPath'],
      thermalPhotoPath: j['thermalPhotoPath'],
      conclusionOverride: j['conclusionOverride'] as bool?,
      updatedAt: _dateFromJson(j['updatedAt']),
    );
  }
}

/// Bir saha görevi: aynı tesis/firma için hazırlanan pano raporları.
class InspectionJob {
  final String id;
  String title;
  SiteProfile profile;
  List<PanelReport> reports;
  final DateTime createdAt;
  DateTime updatedAt;

  InspectionJob({
    required this.id,
    required this.title,
    SiteProfile? profile,
    List<PanelReport>? reports,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : profile = profile ?? SiteProfile(),
        reports = reports ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'profile': profile.toJson(),
        'reports': reports.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory InspectionJob.fromJson(Map<String, dynamic> j) => InspectionJob(
        id: j['id'],
        title: j['title'] ?? '',
        profile: j['profile'] is Map ? SiteProfile.fromJson(Map<String, dynamic>.from(j['profile'])) : null,
        reports: (j['reports'] as List?)?.map((r) => PanelReport.fromJson(Map<String, dynamic>.from(r))).toList(),
        createdAt: _dateFromJson(j['createdAt']),
        updatedAt: _dateFromJson(j['updatedAt']),
      );
}
