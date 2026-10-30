import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart' hide Evaluation;
import 'package:klasorum/report/report_models.dart';
import 'package:klasorum/report/report_pdf.dart';
import 'package:klasorum/report/report_rules.dart';
import 'package:klasorum/report/report_store.dart';
import 'package:klasorum/report/report_template.dart';

/// Örnek Word raporundaki (7_YG-1-AP1.docx) değerlerle görev kurar.
InspectionJob sampleJob() {
  final p = SiteProfile(
    texts: {
      'firmaAdi': 'SYS TESİS YÖNETİM HİZMETLERİ ANONİM ŞİRKETİ',
      'adres': 'ŞEKER MAH. MUHSİN YAZICIOĞLU BULVARI ŞEHİR HASTANESİ KAYSERİ KOCASİNAN NO: 77/',
      'sgkSicil': '28110010112088520381416000',
      'isgKatipId': '26780196',
      'sebekeGerilimi': '380 V / 220 V',
      'enerjiKurulusu': 'KAYSERİ VE CİVARI ELEKTRİK TÜRK ANONİM ŞİRKETİ (KCETAŞ)',
      'sonKontrolTarihi': '-',
      'kullanimAmaci': 'ŞEHİR HASTANESİ İÇİN ELEKTRİK ENERJİSİ',
      'sistemTopraklama': 'GALVANİZ ŞERİT VE 3,5X30',
      'ilaveElektrot': 'ÖRGÜLÜ BAKIR 1X95 VE 1X120',
      'anaEspotansiyel': 'BAKIR VE 3,5X30',
      'temelTopraklamaDirenci': '0,1',
      'anaRcdTest': '500 VE 200',
      'anaRcdAnma': '4.000 VE 5.000',
      'anaKesiciNominal': '4.000 VE 5.000',
      'anaKesiciTipi': 'TERMİK MANYETİK ŞALTER',
      'beslemeGerilim': '0,40 / 0,23',
      'beslemeFrekans': '50',
      'hataAkimi': '1,35',
      'disCevrimEmpedansi': '0,17',
    },
    choices: {
      'yapiCinsi': ['TİCARİ'],
      'topraklayiciTipi': ['TEMEL'],
      'projeVar': ['VAR'],
      'kontrolNedeni': ['PERİYODİK'],
      'tekHatVar': ['VAR'],
      'fazIletken': ['AA', '3 FAZ-4 TEL'],
      'sebekeTipi': ['TN', 'TN-S'],
      'dokunmaOnlemleri': ReportTemplate.dokunmaOnlemleri.options,
      'oncekiEtiket': ['VAR'],
      'kapsamliDegisiklik': ['YOK'],
      'spdVar': ['EVET'],
    },
    thermalDevices: [
      MeasuringDevice(
        name: 'UNI-T UTİ260B',
        calibrationDate: '03.06.2026',
        validity: '1 YIL / 03.06.2027',
        serialNo: 'AT10225010453',
        calibrationNo: '0096K-0626-00104',
      ),
      MeasuringDevice(),
    ],
    measuringDevices: [
      MeasuringDevice(
        name: 'UNI-T UT202 CLAMP METER',
        calibrationDate: '03.06.2026',
        validity: '1 YIL / 03.06.2027',
        serialNo: '53030949WS',
        calibrationNo: '0096K-0626-00092',
      ),
      MeasuringDevice(name: 'CEM DT-6650 MULTIFUNCTION INSTALLATION TESTER'),
    ],
    inspectorName: 'MEHMET AKİF KÖSTEK',
    inspectorProfession: 'ELEKTRİK TEKNİKERİ',
    inspectorDiplomaNo: '215005035',
    inspectorEkipnetNo: 'K2025428218',
    kontrolFirmasiEkli: 'DİNAMİK MÜHENDİSLİK’in',
  );

  final circuits = <Circuit>[
    Circuit(
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
    ),
  ];
  // Örnek rapordaki 76 linye: priz (C16), aydınlatma (B10), boş (B6) ve FCU devreleri.
  for (var i = 1; i <= 76; i++) {
    final isLight = i > 34 && i <= 67;
    final isSpare = i <= 3;
    circuits.add(Circuit(
      name: isSpare ? 'F$i' : (isLight ? 'A${i - 34} AYDINLATMA' : 'P${i - 3} PRİZ'),
      curve: isLight || isSpare ? 'B' : 'C',
      poles: '1',
      icuKa: '6',
      inA: isSpare ? '6' : (isLight ? '10' : '16'),
      ibA: ((i % 15) * 0.45).toStringAsFixed(2).replaceAll('.', ','),
      phaseSection: '1X1X2,5',
      peSection: '1X2,5',
      nSection: '1X2,5',
      izA: '27',
      idnMa: '${18 + i % 11}',
      tdMs: '${13 + i % 17}',
    ));
  }

  final report = PanelReport(
    id: 'r1',
    panelName: 'YG-1-AP1',
    reportNo: 'Elk.26093423',
    start: DateTime(2026, 9, 1, 9, 30),
    end: DateTime(2026, 9, 1, 9, 45),
    reportDate: DateTime(2026, 9, 1),
    nextDate: DateTime(2027, 9, 1),
    criteria: {
      for (final c in ReportTemplate.allCriteria) c.id: Evaluation.uygun,
      'disDarbe': Evaluation.uygulanamaz,
      'anaPotansiyel': Evaluation.uygulanamaz,
      'ekPotansiyel': Evaluation.uygulanamaz,
    },
    thermalPhotoNo: 'IMG_0020',
    thermalPhotoDate: '01.09.2026',
    zlnOhm: '0,28',
    zxOhm: '0,43',
    vff: '399,7',
    vln: '230,7',
    vnpe: '0,7',
    spdType: 'UYGULANAMAZ',
    ikKa: '3,2',
    spdKa: 'UYGULANAMAZ',
    circuits: circuits,
    floorInsulations: [
      FloorInsulation(location: 'YG-1-AP1 ÖNÜ', widthM: '1,25', lengthM: '2,90', resistanceKohm: '4137'),
    ],
  );
  return InspectionJob(id: 'j1', title: 'KAYSERİ', profile: p, reports: [report]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  photoTests();

  test('örnek rapor eksiksiz ve UYGUN', () {
    final job = sampleJob();
    final r = job.reports.single;
    expect(missingFields(r), isEmpty);
    expect(conclusion(r, job.profile), isTrue);
    for (final c in r.circuits) {
      expect(circuitResult(c, profile: job.profile, panelIkKa: r.ikKa), Evaluation.uygun, reason: c.name);
    }
  });

  test('örnek rapordan PDF üretilir', () async {
    final job = sampleJob();
    final bytes = await buildReportPdf(job: job, report: job.reports.single, store: ReportStore());
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(20000));
    final out = File('build/test_report.pdf');
    await out.parent.create(recursive: true);
    await out.writeAsBytes(bytes);
  });

  test('eksik rapor da (taslak) PDF üretir', () async {
    final job = sampleJob();
    final r = job.reports.single..circuits.first.ibA = '';
    expect(missingFields(r), isNotEmpty);
    final bytes = await buildReportPdf(job: job, report: r, store: ReportStore());
    await File('build/test_report_taslak.pdf').writeAsBytes(bytes);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}

// 2x2 kırmızı PNG: logo ve fotoğrafların PDF'e gömülmesini sınamak için.
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAFklEQVR4nGP8z8DAwMDAxMDAwMDAAAANHQEDasKb6QAAAABJRU5ErkJggg==';

void photoTests() {
  test('logo ve fotoğraflar kopyalanır, PDF\'e gömülür, görev silinince temizlenir', () async {
    final tmp = await Directory.systemTemp.createTemp('rapor_test');
    addTearDown(() => tmp.delete(recursive: true));
    final store = ReportStore(docsDir: tmp);
    final src = File('${tmp.path}/kaynak.png')..writeAsBytesSync(base64Decode(_pngBase64));

    final job = await store.createJob('TEST');
    job.profile = sampleJob().profile;
    job.profile.logoPath = await store.importLogo(src.path);
    final report = sampleJob().reports.single;
    report.equipmentPhotoPath = await store.importMedia(job, src.path);
    report.thermalPhotoPath = await store.importMedia(job, src.path);
    job.reports.add(report);
    await store.save(job);

    expect(await store.resolveMedia(report.equipmentPhotoPath), isNotNull);
    final withPhotos = await buildReportPdf(job: job, report: report, store: store);
    final without = await buildReportPdf(job: sampleJob(), report: sampleJob().reports.single, store: store);
    expect(withPhotos.length, greaterThan(without.length));
    await File('build/test_report_foto.pdf').writeAsBytes(withPhotos);

    // Kayıt diskten geri okunur.
    final reloaded = ReportStore(docsDir: tmp);
    await reloaded.load();
    expect(reloaded.jobs.single.reports.single.circuits.length, 77);

    await store.deleteJob(job);
    expect(await store.resolveMedia(report.equipmentPhotoPath), isNull);
    expect(await store.resolveMedia(job.profile.logoPath), isNotNull, reason: 'logo görevden bağımsız saklanır');
  });
}
