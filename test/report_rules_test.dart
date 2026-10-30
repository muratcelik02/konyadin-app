import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:klasorum/report/report_models.dart';
import 'package:klasorum/report/report_rules.dart';
import 'package:klasorum/report/report_template.dart';

void main() {
  final profile = SiteProfile();

  group('Türkçe sayı ve kesit ayrıştırma', () {
    test('ondalık virgül, binlik nokta, tire', () {
      expect(parseTrNumber('0,28'), 0.28);
      expect(parseTrNumber('68,59'), 68.59);
      expect(parseTrNumber('4.000'), 4000);
      expect(parseTrNumber('399,7'), 399.7);
      expect(parseTrNumber('-'), isNull);
      expect(parseTrNumber(''), isNull);
      expect(parseTrNumber('UYGULANAMAZ'), isNull);
    });

    test('kesit yazımları', () {
      expect(parseSectionMm2('1X3X35'), 35);
      expect(parseSectionMm2('1X1X2,5'), 2.5);
      expect(parseSectionMm2('1X16'), 16);
      expect(parseSectionMm2('3x70+35'), 70);
      expect(parseSectionMm2('-'), isNull);
    });

    test('PE asgari kesit tablosu', () {
      expect(minPeSection(2.5), 2.5);
      expect(minPeSection(35), 16);
      expect(minPeSection(95), 47.5);
    });
  });

  group('Örnek rapor (YG-1-AP1) satırları UYGUN çıkmalı', () {
    test('ANA GİRİŞ Q00', () {
      final c = Circuit(
        name: 'ANA GİRİŞ Q00',
        curve: 'TMŞ',
        poles: '3',
        icuKa: '6',
        inA: '100',
        ibA: '68,59',
        phaseSection: '1X3X35',
        peSection: '1X16',
        nSection: '1X35',
        izA: '158',
        idnMa: '-',
        tdMs: '-',
      );
      final check = checkCircuit(c, profile: profile, panelIkKa: '3,2');
      expect(check.issues, isEmpty);
      expect(check.suggested, Evaluation.uygun);
    });

    test('P1 PRİZ+HAV. (C16, RCD 28 mA / 29 ms)', () {
      final c = Circuit(
        curve: 'C',
        poles: '1',
        icuKa: '6',
        inA: '16',
        ibA: '0,45',
        phaseSection: '1X1X2,5',
        peSection: '1X2,5',
        nSection: '1X2,5',
        izA: '27',
        idnMa: '28',
        tdMs: '29',
      );
      expect(checkCircuit(c, profile: profile, panelIkKa: '3,2').suggested, Evaluation.uygun);
    });
  });

  group('Ağır kusurlar UYGUN DEĞİL önerir', () {
    Circuit base() => Circuit(
          curve: 'C',
          poles: '1',
          icuKa: '6',
          inA: '16',
          ibA: '5',
          phaseSection: '1X1X2,5',
          peSection: '1X2,5',
          nSection: '1X2,5',
          izA: '27',
          idnMa: '28',
          tdMs: '29',
        );

    test('In > Iz', () {
      final c = base()..inA = '32';
      expect(checkCircuit(c, profile: profile, panelIkKa: '').suggested, Evaluation.uygunDegil);
    });

    test('Ib > In', () {
      final c = base()..ibA = '18';
      expect(checkCircuit(c, profile: profile, panelIkKa: '').suggested, Evaluation.uygunDegil);
    });

    test('Icu < Ik', () {
      final c = base()..icuKa = '6';
      expect(checkCircuit(c, profile: profile, panelIkKa: '10').suggested, Evaluation.uygunDegil);
    });

    test('RCD açma akımı ve süresi', () {
      expect(checkCircuit(base()..idnMa = '35', profile: profile, panelIkKa: '').suggested, Evaluation.uygunDegil);
      expect(checkCircuit(base()..tdMs = '320', profile: profile, panelIkKa: '').suggested, Evaluation.uygunDegil);
    });

    test('PE kesiti yetersiz', () {
      final c = base()..peSection = '1X1,5';
      expect(checkCircuit(c, profile: profile, panelIkKa: '').suggested, Evaluation.uygunDegil);
    });

    test('N kesiti küçükse yalnızca uyarı', () {
      final c = base()
        ..phaseSection = '1X3X35'
        ..peSection = '1X16'
        ..nSection = '1X16'
        ..inA = '100'
        ..ibA = '60'
        ..izA = '158'
        ..idnMa = '-'
        ..tdMs = '-';
      final check = checkCircuit(c, profile: profile, panelIkKa: '');
      expect(check.issues.single.level, IssueLevel.warn);
      expect(check.suggested, Evaluation.uygun);
    });

    test('Ib/In/Iz eksikse öneri yok', () {
      final c = Circuit(inA: '16');
      expect(checkCircuit(c, profile: profile, panelIkKa: '').suggested, isNull);
    });

    test('teknisyenin kararı öneriyi geçersiz kılar', () {
      final c = base()
        ..inA = '32'
        ..resultOverride = Evaluation.uygulanamaz;
      expect(circuitResult(c, profile: profile, panelIkKa: ''), Evaluation.uygulanamaz);
    });
  });

  group('Tamamlanma kontrolü', () {
    test('boş rapor taslaktır', () {
      final r = PanelReport(id: '1');
      final missing = missingFields(r);
      expect(missing, contains('Pano adı'));
      expect(missing, contains('Fonksiyon test tablosunda devre yok'));
    });

    test('"-" alanı doldurulmuş sayılır, boş alan eksiktir', () {
      final r = PanelReport(
        id: '1',
        panelName: 'YG-1-AP1',
        reportNo: 'Elk.1',
        start: DateTime(2026, 9, 1, 9, 30),
        end: DateTime(2026, 9, 1, 9, 45),
        zlnOhm: '0,28',
        zxOhm: '0,43',
        vff: '399,7',
        vln: '230,7',
        vnpe: '0,7',
        ikKa: '3,2',
        spdType: 'UYGULANAMAZ',
        spdKa: 'UYGULANAMAZ',
        criteria: {for (final c in ReportTemplate.allCriteria) c.id: Evaluation.uygun},
        circuits: [
          Circuit(
            name: 'F1',
            curve: 'B',
            poles: '1',
            icuKa: '6',
            inA: '6',
            ibA: '0,45',
            phaseSection: '1X1X2,5',
            peSection: '1X2,5',
            nSection: '1X2,5',
            izA: '27',
            idnMa: '-',
            tdMs: '-',
          ),
        ],
        floorInsulations: [FloorInsulation(location: 'ÖN', resistanceKohm: '4137')],
      );
      expect(missingFields(r), isEmpty);

      r.circuits.first.ibA = '';
      expect(missingFields(r).single, startsWith('Devre 1 (F1): 1 boş alan'));
    });

    test('UYGUN DEĞİL kriter sonucu UYGUN DEĞİLDİR yapar', () {
      final r = PanelReport(id: '1', criteria: {'kabloSebeke': Evaluation.uygunDegil});
      expect(conclusion(r, profile), isFalse);
      r.conclusionOverride = true;
      expect(conclusion(r, profile), isTrue);
    });

    test('zemin izolasyonu 50 kΩ eşiği', () {
      expect(floorSuggested(FloorInsulation(resistanceKohm: '4137'), profile), Evaluation.uygun);
      expect(floorSuggested(FloorInsulation(resistanceKohm: '40'), profile), Evaluation.uygunDegil);
    });
  });

  test('JSON gidiş-dönüş veriyi korur', () {
    final job = InspectionJob(id: 'j', title: 'TEST');
    job.profile.texts['firmaAdi'] = 'SYS TESİS';
    job.profile.choices['sebekeTipi'] = ['TN', 'TN-S'];
    job.reports.add(PanelReport(
      id: 'r',
      panelName: 'YG-1-AP1',
      start: DateTime(2026, 9, 1, 9, 30),
      criteria: {'kabloSebeke': Evaluation.uygulanamaz},
      circuits: [Circuit(name: 'F1', ibA: '0,45', resultOverride: Evaluation.uygunDegil)],
      conclusionOverride: false,
    ));
    final back = InspectionJob.fromJson(job.toJson());
    expect(back.profile.text('firmaAdi'), 'SYS TESİS');
    expect(back.profile.choice('sebekeTipi'), ['TN', 'TN-S']);
    final r = back.reports.single;
    expect(r.start, DateTime(2026, 9, 1, 9, 30));
    expect(r.criteria['kabloSebeke'], Evaluation.uygulanamaz);
    expect(r.circuits.single.ibA, '0,45');
    expect(r.circuits.single.resultOverride, Evaluation.uygunDegil);
    expect(r.conclusionOverride, isFalse);
  });

  test('tarih biçimi rapordaki gibi', () {
    expect(formatDateTime(DateTime(2026, 9, 1, 9, 30)), '01.09.2026 VE 09:30');
    expect(formatDate(null), '-');
  });
}
