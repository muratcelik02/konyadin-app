import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'report_models.dart';
import 'report_rules.dart';
import 'report_store.dart';
import 'report_template.dart';

const _border = 0.5;
const _small = 6.5;
const _normal = 7.5;
final _headerFill = PdfColor.fromInt(0xFFD9E2F3);
final _labelFill = PdfColor.fromInt(0xFFF2F2F2);

/// Fonksiyon test tablosu sütun genişlikleri (oransal). Grup başlığı aynı oranları kullanır.
const _colFlex = [16, 100, 26, 24, 32, 30, 34, 50, 36, 36, 34, 30, 30, 55];

Future<Uint8List> buildReportPdf({
  required InspectionJob job,
  required PanelReport report,
  required ReportStore store,
}) async {
  final base = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSansCondensed.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSansCondensed-Bold.ttf'));
  final profile = job.profile;

  Future<pw.MemoryImage?> image(String? path) async {
    final f = await store.resolveMedia(path);
    return f == null ? null : pw.MemoryImage(await f.readAsBytes());
  }

  final logo = await image(profile.logoPath);
  final equipmentPhoto = await image(report.equipmentPhotoPath);
  final thermalPhoto = await image(report.thermalPhotoPath);
  final isDraft = missingFields(report).isNotEmpty;
  final uygun = conclusion(report, profile);

  final doc = pw.Document(
    title: '${report.reportNo} ${report.panelName}',
    author: profile.inspectorName,
  );

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 20, 28, 20),
        theme: pw.ThemeData.withFont(base: base, bold: bold).copyWith(
          defaultTextStyle: pw.TextStyle(font: base, fontBold: bold, fontSize: _normal),
        ),
        buildForeground: isDraft
            ? (ctx) => pw.Watermark.text(
                  'TASLAK',
                  style: pw.TextStyle(font: bold, fontSize: 90, color: PdfColor.fromInt(0x33CC0000)),
                )
            : null,
      ),
      header: (ctx) => _header(logo),
      footer: (ctx) => _footer(ctx, profile, report),
      build: (ctx) => [
        ..._firmaBilgileri(profile, report),
        ..._ekipmanBilgileri(profile),
        ..._cihazlar('3. TERMAL KAMERA BİLGİLERİ', profile.thermalDevices),
        ..._cihazlar('4. ÖLÇÜM ALETLERİ BİLGİLERİ', profile.measuringDevices),
        ..._kontrolKriterleri(report),
        ..._fonksiyonTestleri(profile, report),
        _keep([_sectionTitle('7. KUSUR AÇIKLAMALARI'), _box(pw.Text(orDash(report.defects)))]),
        _keep([_sectionTitle('8. EKİPMAN FOTOĞRAFLARI'), _photos(report, equipmentPhoto, thermalPhoto)]),
        _keep([
          _sectionTitle('9. NOTLAR'),
          _box(pw.Text(ReportTemplate.notlar, textAlign: pw.TextAlign.justify)),
        ]),
        _sectionTitle('10. SONUÇ VE KANAAT'),
        _box(pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(
            ReportTemplate.sonucMetni(uygun: uygun, sonrakiTarih: formatDate(report.nextDate)),
            style: pw.TextStyle(font: bold),
            textAlign: pw.TextAlign.justify,
          ),
          pw.SizedBox(height: 3),
          pw.Text(ReportTemplate.agirKusurTanimlari,
              style: const pw.TextStyle(fontSize: _small), textAlign: pw.TextAlign.justify),
        ])),
        ..._yetkili(profile),
      ],
    ),
  );
  return doc.save();
}

// ---------- Ortak parçalar ----------

pw.Widget _header(pw.MemoryImage? logo) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 6),
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: _border))),
      child: pw.Row(children: [
        pw.SizedBox(width: 90, height: 34, child: logo == null ? null : pw.Image(logo, fit: pw.BoxFit.contain)),
        pw.Expanded(
          child: pw.Column(children: [
            pw.Text(ReportTemplate.headerLine1, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text(ReportTemplate.headerLine2, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Text(ReportTemplate.headerLine3, style: const pw.TextStyle(fontSize: 9)),
          ]),
        ),
        pw.SizedBox(width: 90),
      ]),
    );

pw.Widget _footer(pw.Context ctx, SiteProfile profile, PanelReport report) => pw.Column(children: [
      pw.Text(
        ReportTemplate.footerMetni(orDash(profile.kontrolFirmasiEkli)),
        style: const pw.TextStyle(fontSize: 5.5),
        textAlign: pw.TextAlign.justify,
      ),
      pw.SizedBox(height: 2),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Rapor No: ${orDash(report.reportNo)} - Paraf:', style: const pw.TextStyle(fontSize: _small)),
        pw.Text('Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}', style: const pw.TextStyle(fontSize: _small)),
      ]),
    ]);

pw.Widget _sectionTitle(String text) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
      decoration: pw.BoxDecoration(color: _headerFill, border: pw.Border.all(width: _border)),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5)),
    );

pw.Widget _subTitle(String text) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: pw.BoxDecoration(color: _labelFill, border: pw.Border.all(width: _border)),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );

/// Başlık ve içeriği aynı sayfada tutar (sayfa sonunda yetim başlık kalmaz).
pw.Widget _keep(List<pw.Widget> children) =>
    pw.Inseparable(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: children));

pw.Widget _box(pw.Widget child) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: _border)),
      child: child,
    );

pw.Widget _cell(String text, {bool bold = false, bool fill = false, double size = _normal, pw.TextAlign? align}) =>
    pw.Container(
      color: fill ? _labelFill : null,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );

/// Etiket | değer | etiket | değer satırları; iki elemanlı satır tek çift olarak tam genişlikte basılır.
/// Aynı yapıdaki ardışık satırlar tek tabloda toplanır; tablolar sayfa sonunda satır satır bölünür.
List<pw.Widget> _kvTable(List<List<String?>> rows) {
  final tables = <pw.Widget>[];
  var i = 0;
  while (i < rows.length) {
    final four = rows[i].length > 2;
    final run = <List<String?>>[];
    while (i < rows.length && (rows[i].length > 2) == four) {
      run.add(rows[i++]);
    }
    tables.add(pw.Table(
      border: pw.TableBorder.all(width: _border),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
      columnWidths: four
          ? const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(3),
              3: pw.FlexColumnWidth(3)
            }
          : const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(9)},
      children: [
        for (final r in run)
          pw.TableRow(children: [
            _cell(r[0]!, fill: true),
            _cell(r[1] ?? '-'),
            if (four) ...[_cell(r[2]!, fill: true), _cell(r[3] ?? '-')],
          ]),
      ],
    ));
  }
  return tables;
}

/// Seçim alanını rapordaki gibi basar: ○EV●TİCARİ○ENDÜSTRİ
String choiceText(ChoiceFieldDef def, List<String> selected) =>
    def.options.map((o) => '${selected.contains(o) ? '●' : '○'}$o').join(' ');

// ---------- Bölümler ----------

List<pw.Widget> _firmaBilgileri(SiteProfile p, PanelReport r) => [
      _sectionTitle('1. FİRMA BİLGİLERİ'),
      ..._kvTable([
        ['Firma Adı', orDash(p.text('firmaAdi')), 'Rapor Numarası', orDash(r.reportNo)],
        ['Periyodik Kontrol Adresi', orDash(p.text('adres'))],
        [
          'Periyodik Kontrol Başlangıç Tarihi ve Saati',
          formatDateTime(r.start),
          'SGK Sicil Numarası',
          orDash(p.text('sgkSicil'))
        ],
        [
          'Periyodik Kontrol Bitiş Tarihi ve Saati',
          formatDateTime(r.end),
          'İSG-KÂTİP Sözleşme ID',
          orDash(p.text('isgKatipId'))
        ],
        ['Bir Sonraki Periyodik Kontrol Tarihi', formatDate(r.nextDate), 'Rapor Tarihi', formatDate(r.reportDate)],
      ]),
      _subTitle('PERİYODİK KONTROL METODU VE KAPSAMI'),
      _box(pw.Text(ReportTemplate.kontrolKapsami, style: const pw.TextStyle(fontSize: _small))),
    ];

List<pw.Widget> _ekipmanBilgileri(SiteProfile p) {
  String t(String id) => orDash(p.text(id));
  String c(ChoiceFieldDef d) => choiceText(d, p.choice(d.id));
  return [
    _sectionTitle('2. EKİPMAN BİLGİLERİ'),
    _subTitle('ETİKET VE DETAY BİLGİLERİ'),
    ..._kvTable([
      ['Yapı Cinsi', c(ReportTemplate.yapiCinsi), 'Şebeke Gerilimi', t('sebekeGerilimi')],
      ['Topraklayıcı Tipi', c(ReportTemplate.topraklayiciTipi), 'Tesise Ait Proje Var Mı?', c(ReportTemplate.projeVar)],
      ['Kontrol Nedeni', c(ReportTemplate.kontrolNedeni), 'Tek Hat Şeması Var Mı?', c(ReportTemplate.tekHatVar)],
      ['Enerji Sağlayan Kuruluş', t('enerjiKurulusu'), 'Son Kontrol Tarihi', t('sonKontrolTarihi')],
      ['Faz İletkenlerinin Sayısı ve Tipi', c(ReportTemplate.fazIletken)],
      ['Ekipmanın Kullanım Amacı', t('kullanimAmaci'), 'Şebeke Tipi', c(ReportTemplate.sebekeTipi)],
      [
        'Sistem Topraklama İletkeni ve Kesiti (mm2)',
        t('sistemTopraklama'),
        'İlave Topraklama Elektrodu Detayları',
        t('ilaveElektrot')
      ],
      [
        'Ana Eşpotansiyel İletkeni ve Kesiti (mm2)',
        t('anaEspotansiyel'),
        'Temel Topraklama Direnci (Ω)',
        t('temelTopraklamaDirenci')
      ],
      [
        'TT-TNS Şebeke İçin Ana RCD Test Akımı (mA) ve Test Süresi (ms)',
        t('anaRcdTest'),
        'TT-TNS Şebeke İçin Ana RCD Anma Akımı (A)',
        t('anaRcdAnma'),
      ],
    ]),
    _subTitle('Ana Kesici Karakteristikleri'),
    ..._kvTable([
      ['Nominal Akımı (A)', t('anaKesiciNominal'), 'Tipi', t('anaKesiciTipi')],
    ]),
    _subTitle('Besleme Kaynağı Karakteristikleri'),
    ..._kvTable([
      ['Nominal Gerilimi U/U0 (kV)', t('beslemeGerilim'), 'Nominal Frekansı f(1) (Hz)', t('beslemeFrekans')],
      ['Hata Akım Olasılığı IF (kA)', t('hataAkimi'), 'Dış Çevrim Empedansı ZE (Ω)', t('disCevrimEmpedansi')],
    ]),
    _subTitle('TESPİT EDİLEN BİLGİLER'),
    ..._kvTable([
      [ReportTemplate.dokunmaOnlemleri.label, c(ReportTemplate.dokunmaOnlemleri)],
      [
        ReportTemplate.oncekiEtiket.label,
        c(ReportTemplate.oncekiEtiket),
        ReportTemplate.kapsamliDegisiklik.label,
        c(ReportTemplate.kapsamliDegisiklik),
      ],
      [ReportTemplate.spdVar.label, c(ReportTemplate.spdVar)],
    ]),
  ];
}

List<pw.Widget> _cihazlar(String title, List<MeasuringDevice> devices) {
  MeasuringDevice d(int i) => i < devices.length ? devices[i] : MeasuringDevice();
  final a = d(0), b = d(1);
  return [
    _sectionTitle(title),
    ..._kvTable([
      ['Cihaz Adı', orDash(a.name), 'Cihaz Adı', orDash(b.name)],
      ['Kalibrasyon Tarihi', orDash(a.calibrationDate), 'Kalibrasyon Tarihi', orDash(b.calibrationDate)],
      ['Kalibrasyon Geçerlilik Tarihi', orDash(a.validity), 'Kalibrasyon Geçerlilik Tarihi', orDash(b.validity)],
      ['Seri Numarası', orDash(a.serialNo), 'Seri Numarası', orDash(b.serialNo)],
      ['Kalibrasyon Numarası', orDash(a.calibrationNo), 'Kalibrasyon Numarası', orDash(b.calibrationNo)],
    ]),
  ];
}

List<pw.Widget> _kontrolKriterleri(PanelReport r) {
  String ev(String id) => r.criteria[id]?.label ?? '-';
  final widgets = <pw.Widget>[
    _sectionTitle('5. KONTROL KRİTERLERİ VE TESTLER'),
    _subTitle('TEST VE KONTROLLER'),
    ..._kvTable([
      ['Pano Adı/Ekipman Tanımlaması', orDash(r.panelName)],
    ]),
  ];
  for (final g in ReportTemplate.criteriaGroups) {
    final rows = <List<String?>>[];
    for (var i = 0; i < g.items.length; i += 2) {
      final a = g.items[i];
      if (i + 1 < g.items.length) {
        final b = g.items[i + 1];
        rows.add([a.label, ev(a.id), b.label, ev(b.id)]);
      } else {
        rows.add([a.label, ev(a.id)]);
      }
    }
    if (g.items.any((c) => c.id == 'asiriYuk')) {
      rows.add(['Fotoğraf numarası', orDash(r.thermalPhotoNo), 'Fotoğraf tarihi', orDash(r.thermalPhotoDate)]);
    }
    // Grup başlığı tablosuyla birlikte kalsın: sayfa sonunda tek başına başlık kalmaz.
    widgets.add(_keep([_subTitle(g.title), ..._kvTable(rows)]));
  }
  return widgets;
}

List<pw.Widget> _fonksiyonTestleri(SiteProfile p, PanelReport r) {
  final headers = [
    'No.',
    'Pano/tablo numarası-linye adı-etiketi',
    'Açma eğrisi tipi',
    'Kutup sayısı',
    'Kısa devre kesme akımı Icu (kA)',
    'Nominal akım In (A)',
    'Tasarım (yük) akımı Ib (A)',
    'Faz kesiti (mm²)',
    'PE koruma iletkeni kesiti (mm²)',
    'N/PEN kesiti (mm²)',
    'Akım taşıma kapasitesi (Iz) (A)',
    'Açma akımı IΔ (mA)',
    'Açma akımı TΔ (ms)',
    'Sonuç (Not)',
  ];

  pw.Widget groupCell(String text, int fromCol, int toCol) {
    final flex = _colFlex.sublist(fromCol, toCol + 1).reduce((a, b) => a + b);
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        height: 14,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(color: _headerFill, border: pw.Border.all(width: _border)),
        child: pw.Text(text, style: pw.TextStyle(fontSize: _small, fontWeight: pw.FontWeight.bold)),
      ),
    );
  }

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: pw.BoxDecoration(color: _headerFill),
      repeat: true,
      children: [for (final h in headers) _cell(h, bold: true, size: 5.5, align: pw.TextAlign.center)],
    ),
  ];
  for (var i = 0; i < r.circuits.length; i++) {
    final c = r.circuits[i];
    final result = circuitResult(c, profile: p, panelIkKa: r.ikKa);
    final note = isFilled(c.note) ? ' (${c.note.trim()})' : '';
    final values = [
      '${i + 1}.',
      orDash(c.name),
      orDash(c.curve),
      orDash(c.poles),
      orDash(c.icuKa),
      orDash(c.inA),
      orDash(c.ibA),
      orDash(c.phaseSection),
      orDash(c.peSection),
      orDash(c.nSection),
      orDash(c.izA),
      orDash(c.idnMa),
      orDash(c.tdMs),
      '${result?.label ?? '-'}$note',
    ];
    rows.add(pw.TableRow(children: [
      for (var k = 0; k < values.length; k++)
        _cell(values[k], size: _small, align: k == 1 || k == 13 ? pw.TextAlign.left : pw.TextAlign.center),
    ]));
  }

  return [
    _sectionTitle('6. FONKSİON KONTROL KRİTERLERİ VE TESTLER'),
    ..._kvTable([
      ['Ölçüm ve Doğrulama Metodu', choiceText(ReportTemplate.olcumMetodu, r.method)],
    ]),
    _subTitle(
        'AŞIRI AKIM CİHAZI, İLETKEN UYGUNLUĞU, GERİLİM KONTROLÜ, AŞIRI GERİM CİHAZLARI (DKD) KONTROLÜ VE (ARTIK AKIM ANAHTARI) RCD TESTLERİ'),
    ..._kvTable([
      ['Pano (Ekipman) Adı-Etiketi veya Kodu', orDash(r.panelName)],
      [
        'Panodan ölçülen faz-nötr çevrim empedansı (ZLN) (Ω)',
        orDash(r.zlnOhm),
        'Panodan ölçülen faz-toprak çevrim empedansı (Zx) (Ω)',
        orDash(r.zxOhm)
      ],
      ['Gerilimler F-F (V)', orDash(r.vff), 'Gerilimler L-N (V)', orDash(r.vln)],
      ['Gerilimler N-PE (V)', orDash(r.vnpe), 'Hesaplanan 3 fazlı kısa devre akımı (Ik) (kA)', orDash(r.ikKa)],
      [
        'Aşırı gerilim koruma (DKD) tipi',
        orDash(r.spdType),
        'Aşırı gerilim koruma (DKD) dayanma akımı (kA)',
        orDash(r.spdKa)
      ],
    ]),
    pw.SizedBox(height: 3),
    pw.Row(children: [
      groupCell('', 0, 1),
      groupCell('Aşırı Akım Koruma Cihazının', 2, 5),
      groupCell('İletkenin', 6, 10),
      groupCell('RCD Testi', 11, 12),
      groupCell('', 13, 13),
    ]),
    pw.Table(
      border: pw.TableBorder.all(width: _border),
      columnWidths: {for (var k = 0; k < _colFlex.length; k++) k: pw.FlexColumnWidth(_colFlex[k].toDouble())},
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    ),
    _subTitle('ZEMİN İZOLASYONUNUN KONTROLÜ'),
    pw.Table(
      border: pw.TableBorder.all(width: _border),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(6),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(3),
        5: pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _labelFill),
          children: [
            for (final h in [
              'No.',
              'İzolasyon halısının (zemin yalıtımının) yeri',
              'Eni (m)',
              'Boyu (m)',
              'Zemin izolasyon direnci (kΩ)',
              'Sonuç (Uygunluk notu)',
            ])
              _cell(h, bold: true, size: _small, align: pw.TextAlign.center),
          ],
        ),
        for (var i = 0; i < r.floorInsulations.length; i++)
          pw.TableRow(children: [
            _cell('${i + 1}.', size: _small, align: pw.TextAlign.center),
            _cell(orDash(r.floorInsulations[i].location), size: _small),
            _cell(orDash(r.floorInsulations[i].widthM), size: _small, align: pw.TextAlign.center),
            _cell(orDash(r.floorInsulations[i].lengthM), size: _small, align: pw.TextAlign.center),
            _cell(orDash(r.floorInsulations[i].resistanceKohm), size: _small, align: pw.TextAlign.center),
            _cell(floorResult(r.floorInsulations[i], p)?.label ?? '-', size: _small, align: pw.TextAlign.center),
          ]),
      ],
    ),
  ];
}

pw.Widget _photos(PanelReport r, pw.MemoryImage? equipment, pw.MemoryImage? thermal) {
  // Fotoğraf yoksa alan küçülür; rapor boş kutular yüzünden sayfa kaybetmez.
  final height = equipment == null && thermal == null ? 40.0 : 210.0;
  pw.Widget slot(String caption, pw.MemoryImage? img) => pw.Expanded(
        child: pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: _border)),
          child: pw.Column(children: [
            _cell(caption, bold: true, align: pw.TextAlign.center),
            pw.Container(
              height: height,
              padding: const pw.EdgeInsets.all(3),
              alignment: pw.Alignment.center,
              child: img == null ? pw.Text('-') : pw.Image(img, fit: pw.BoxFit.contain),
            ),
          ]),
        ),
      );
  return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    slot(orDash(r.panelName), equipment),
    slot('TERMAL FOTOĞRAF', thermal),
  ]);
}

List<pw.Widget> _yetkili(SiteProfile p) => [
      _keep([
        _sectionTitle('11. PERİYODİK KONTROLLLERİ YAPMAYA YETKİLİ KİŞİ BİLGİLERİ VE ONAY'),
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: _border)),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                  children: _kvTable([
                ['Adı Soyadı', orDash(p.inspectorName)],
                ['Mesleği', orDash(p.inspectorProfession)],
                ['Diploma Numarası', orDash(p.inspectorDiplomaNo)],
                ['Ekipnet Kayıt Numarası', orDash(p.inspectorEkipnetNo)],
              ])),
            ),
            pw.Expanded(
              child: pw.Column(children: [
                _cell('İmzası', bold: true, fill: true, align: pw.TextAlign.center),
                pw.SizedBox(height: 50),
              ]),
            ),
          ]),
        ),
        pw.SizedBox(height: 4),
        pw.Text(ReportTemplate.nushaMetni, style: const pw.TextStyle(fontSize: _small)),
      ]),
    ];
