import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'report_models.dart';
import 'report_rules.dart';
import 'report_store.dart';
import 'report_template.dart';

// Word şablonundaki ölçüler: gövde 8 pt, bölüm başlıkları 9 pt, başlık zemini #D9D9D9.
const _border = 0.6;
const _pageMarginX = 28.0;
const _fs = 8.0;
const _fsSmall = 7.0;
const _titleFill = PdfColor.fromInt(0xFFD9D9D9);

/// Fonksiyon test tablosu sütun genişlikleri (oransal). Grup başlığı aynı oranları kullanır.
const _colFlex = [16, 92, 24, 24, 34, 30, 34, 40, 38, 30, 38, 28, 28, 34];

Future<Uint8List> buildReportPdf({
  required InspectionJob job,
  required PanelReport report,
  required ReportStore store,
}) async {
  // Carlito, Word şablonundaki Calibri ile aynı ölçülerde açık lisanslı bir yazı tipidir.
  // Carlito'da olmayan semboller (● ○ Ω Δ ≤) için DejaVu yedek olarak kullanılır.
  final base = pw.Font.ttf(await rootBundle.load('assets/fonts/Carlito-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Carlito-Bold.ttf'));
  final boldItalic = pw.Font.ttf(await rootBundle.load('assets/fonts/Carlito-BoldItalic.ttf'));
  final fallback = [
    pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSansCondensed.ttf')),
    pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSansCondensed-Bold.ttf')),
  ];
  final profile = job.profile;

  Future<pw.MemoryImage?> image(String? path) async {
    final bytes = await store.readMedia(path);
    return bytes == null ? null : pw.MemoryImage(bytes);
  }

  // Başlık bandı: görev ayarlarında seçilen resim, yoksa Word şablonundaki bant.
  final banner = await image(profile.logoPath) ??
      pw.MemoryImage((await rootBundle.load('assets/report/header_banner.jpg')).buffer.asUint8List());
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
        margin: const pw.EdgeInsets.fromLTRB(_pageMarginX, 12, _pageMarginX, 16),
        theme: pw.ThemeData.withFont(base: base, bold: bold, boldItalic: boldItalic, fontFallback: fallback).copyWith(
          defaultTextStyle: pw.TextStyle(
            font: base,
            fontBold: bold,
            fontBoldItalic: boldItalic,
            fontFallback: fallback,
            fontSize: _fs,
          ),
        ),
        buildForeground: isDraft
            ? (ctx) => pw.Watermark.text(
                  'TASLAK',
                  style: pw.TextStyle(font: bold, fontSize: 90, color: const PdfColor.fromInt(0x33CC0000)),
                )
            : null,
      ),
      header: (ctx) => _header(banner),
      footer: (ctx) => _footer(ctx, profile, report),
      build: (ctx) => [
        ..._firmaBilgileri(profile, report),
        ..._ekipmanBilgileri(profile),
        ..._cihazlar('3. TERMAL KAMERA BİLGİLERİ', profile.thermalDevices),
        ..._cihazlar('4. ÖLÇÜM ALETLERİ BİLGİLERİ', profile.measuringDevices),
        ..._kontrolKriterleri(report),
        ..._fonksiyonTestleri(profile, report),
        _keep([_sectionTitle('7. KUSUR AÇIKLAMALARI'), _box(pw.Text(report.defects.trim()), minHeight: 14)]),
        _keep([_sectionTitle('8. EKİPMAN FOTOĞRAFLARI'), _photos(report, equipmentPhoto, thermalPhoto)]),
        _keep([
          _sectionTitle('9. NOTLAR'),
          _box(pw.Text(ReportTemplate.notlar, textAlign: pw.TextAlign.justify)),
        ]),
        ..._sonuc(report, uygun),
        ..._yetkili(profile),
      ],
    ),
  );
  return doc.save();
}

// ---------- Ortak parçalar ----------

/// Word şablonundaki başlık: tam genişlik bant (solda logo, sağda firma iletişim bilgileri),
/// ilk iki başlık satırı bandın ortasında, "Periyodik Kontrol Raporu" hemen altında.
pw.Widget _header(pw.MemoryImage banner) {
  // Bant sayfa genişliğine yayılır; yüksekliği resmin kendi oranından gelir (kare bir logo
  // seçilirse başlık sayfayı kaplamasın diye en fazla 80 pt).
  final width = PdfPageFormat.a4.width - _pageMarginX * 2;
  final ratio = (banner.width ?? 1936) / (banner.height ?? 204);
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Column(children: [
      pw.Stack(alignment: pw.Alignment.center, children: [
        pw.SizedBox(width: width, height: math.min(width / ratio, 80), child: pw.Image(banner, fit: pw.BoxFit.contain)),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
            pw.Text(ReportTemplate.headerLine1,
                style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15.5)),
            pw.SizedBox(height: 2),
            pw.Text(ReportTemplate.headerLine2,
                style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14.5)),
          ]),
        ),
      ]),
      pw.Text(ReportTemplate.headerLine3, style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11.5)),
    ]),
  );
}

/// Word şablonundaki altbilgi: ilk sayfada yalnız "Paraf:", diğerlerinde rapor numarası;
/// sağda şablondaki gibi "Sayfa <toplam> | <sayfa>".
pw.Widget _footer(pw.Context ctx, SiteProfile profile, PanelReport report) => pw.Column(children: [
      pw.Text(
        ReportTemplate.footerMetni(isFilled(profile.kontrolFirmasiEkli)
            ? profile.kontrolFirmasiEkli.trim()
            : ReportTemplate.defaultKontrolFirmasiEkli),
        style: const pw.TextStyle(fontSize: 7.5),
        textAlign: pw.TextAlign.justify,
      ),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 8),
            child: pw.Text(
              ctx.pageNumber == 1 ? 'Paraf:' : 'Rapor No: ${orDash(report.reportNo)} - Paraf:',
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ),
          pw.RichText(
            text: pw.TextSpan(style: const pw.TextStyle(fontSize: 7.5), children: [
              const pw.TextSpan(text: 'Sayfa '),
              pw.TextSpan(text: '${ctx.pagesCount}', style: const pw.TextStyle(fontSize: 11)),
              pw.TextSpan(text: ' | ${ctx.pageNumber}'),
            ]),
          ),
        ],
      ),
    ]);

/// Word'deki bölüm başlığı: gri zemin, kalın, altı çizili.
pw.Widget _sectionTitle(String text) => pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 5),
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
      decoration: pw.BoxDecoration(color: _titleFill, border: pw.Border.all(width: _border)),
      child: pw.Text(text,
          style:
              const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, decoration: pw.TextDecoration.underline)),
    );

/// Word'deki alt başlık: ortalı, altı çizili; bazıları kalın.
pw.Widget _subTitle(String text, {bool bold = true}) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: _border)),
      child: pw.Text(text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            decoration: pw.TextDecoration.underline,
          )),
    );

/// Başlık ve içeriği aynı sayfada tutar (sayfa sonunda yetim başlık kalmaz).
pw.Widget _keep(List<pw.Widget> children) =>
    pw.Inseparable(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: children));

pw.Widget _box(pw.Widget child, {double? minHeight}) => pw.Container(
      width: double.infinity,
      constraints: minHeight == null ? null : pw.BoxConstraints(minHeight: minHeight),
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: pw.BoxDecoration(border: pw.Border.all(width: _border)),
      child: child,
    );

pw.Widget _cell(
  String text, {
  bool bold = false,
  bool underline = false,
  double size = _fs,
  pw.TextAlign align = pw.TextAlign.left,
}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: size,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            decoration: underline ? pw.TextDecoration.underline : null,
          )),
    );

/// Word'deki değer hücresi: kalın, ortalı.
pw.Widget _value(String text, {double size = _fs}) => _cell(text, bold: true, size: size, align: pw.TextAlign.center);

/// Etiket | değer | etiket | değer satırları; iki elemanlı satır tek çift olarak tam genişlikte basılır.
/// Word'deki gibi etiketler düz (labelBold ile kalın), değerler kalın ve ortalıdır.
/// Aynı yapıdaki ardışık satırlar tek tabloda toplanır; tablolar sayfa sonunda satır satır bölünür.
List<pw.Widget> _kvTable(List<List<String?>> rows, {bool labelBold = false}) {
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
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
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
            _cell(r[0]!, bold: labelBold),
            _value(r[1] ?? '-'),
            if (four) ...[_cell(r[2]!, bold: labelBold), _value(r[3] ?? '-')],
          ]),
      ],
    ));
  }
  return tables;
}

/// Seçim alanını rapordaki gibi basar: ○EV   ●TİCARİ   ○ENDÜSTRİ
String choiceText(ChoiceFieldDef def, List<String> selected) =>
    def.options.map((o) => '${selected.contains(o) ? '●' : '○'}$o').join('   ');

// ---------- Bölümler ----------

List<pw.Widget> _firmaBilgileri(SiteProfile p, PanelReport r) => [
      _sectionTitle('1. FİRMA BİLGİLERİ'),
      ..._kvTable(labelBold: true, [
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
      _box(pw.Text(ReportTemplate.kontrolKapsami, textAlign: pw.TextAlign.justify)),
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
        'Sistem Topraklama İletkeni ve Kesiti (mm²)',
        t('sistemTopraklama'),
        'İlave Topraklama Elektrodu Detayları',
        t('ilaveElektrot')
      ],
      [
        'Ana Eşpotansiyel İletkeni ve Kesiti (mm²)',
        t('anaEspotansiyel'),
        'Temel Topraklama Direnci (Ω)',
        t('temelTopraklamaDirenci')
      ],
      [
        'TT-TNS Şebeke İçin Ana RCD (Artık Akım Anahtarı) Test Akımı (mA) ve Test Süresi (ms)',
        t('anaRcdTest'),
        'TT-TNS Şebeke İçin Ana RCD (Artık Akım Anahtarı) Anma Akımı (A)',
        t('anaRcdAnma'),
      ],
    ]),
    _subTitle('Ana Kesici Karakteristikleri', bold: false),
    ..._kvTable([
      ['Nominal Akımı (A)', t('anaKesiciNominal'), 'Tipi', t('anaKesiciTipi')],
    ]),
    _subTitle('Besleme Kaynağı Karakteristikleri', bold: false),
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
    _keep([
      _sectionTitle(title),
      ..._kvTable([
        ['Cihaz Adı', orDash(a.name), 'Cihaz Adı', orDash(b.name)],
        ['Kalibrasyon Tarihi', orDash(a.calibrationDate), 'Kalibrasyon Tarihi', orDash(b.calibrationDate)],
        ['Kalibrasyon Geçerlilik Tarihi', orDash(a.validity), 'Kalibrasyon Geçerlilik Tarihi', orDash(b.validity)],
        ['Seri Numarası', orDash(a.serialNo), 'Seri Numarası', orDash(b.serialNo)],
        ['Kalibrasyon Numarası', orDash(a.calibrationNo), 'Kalibrasyon Numarası', orDash(b.calibrationNo)],
      ]),
    ]),
  ];
}

/// Kontrol kriterleri tablosu: Word'deki gibi geniş kriter, dar değerlendirme sütunu.
const _criteriaWidths = {
  0: pw.FlexColumnWidth(7),
  1: pw.FlexColumnWidth(3),
  2: pw.FlexColumnWidth(7),
  3: pw.FlexColumnWidth(3),
};

pw.Widget _criteriaTable(List<pw.TableRow> rows) => pw.Table(
      border: pw.TableBorder.all(width: _border),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: _criteriaWidths,
      children: rows,
    );

List<pw.Widget> _kontrolKriterleri(PanelReport r) {
  String ev(String id) => r.criteria[id]?.label ?? '-';
  pw.TableRow pair(String l1, String v1, [String? l2, String? v2]) => pw.TableRow(children: [
        _cell(l1),
        _value(v1),
        _cell(l2 ?? ''),
        l2 == null ? pw.SizedBox() : _value(v2 ?? '-'),
      ]);

  // Bölüm başlığı, sütun başlıkları ve ilk kriter grubu aynı blokta: sayfa sonunda tek başına kalmaz.
  final heading = <pw.Widget>[
    _sectionTitle('5. KONTROL KRİTERLERİ VE TESTLER'),
    _subTitle('TEST VE KONTROLLER'),
    ..._kvTable(labelBold: true, [
      ['Pano Adı/Ekipman Tanımlaması', orDash(r.panelName)],
    ]),
    _criteriaTable([
      pw.TableRow(children: [
        for (final h in ['KONTROL KRİTERİ', 'DEĞERLENDİRME', 'KONTROL KRİTERİ', 'DEĞERLENDİRME'])
          _cell(h, bold: true, underline: true, align: pw.TextAlign.center),
      ]),
    ]),
  ];
  final widgets = <pw.Widget>[];
  for (final g in ReportTemplate.criteriaGroups) {
    final rows = <pw.TableRow>[];
    for (var i = 0; i < g.items.length; i += 2) {
      final a = g.items[i];
      final b = i + 1 < g.items.length ? g.items[i + 1] : null;
      rows.add(pair(a.label, ev(a.id), b?.label, b == null ? null : ev(b.id)));
    }
    if (g.items.any((c) => c.id == 'asiriYuk')) {
      rows.add(pair('Fotoğraf numarası', orDash(r.thermalPhotoNo), 'Fotoğraf tarihi', orDash(r.thermalPhotoDate)));
    }
    widgets.add(_keep([
      if (widgets.isEmpty) ...heading,
      _subTitle(g.title, bold: false),
      _criteriaTable(rows),
    ]));
  }
  return widgets;
}

List<pw.Widget> _fonksiyonTestleri(SiteProfile p, PanelReport r) {
  // (başlık, altı çizili mi) — Word'de No., linye adı ve sonuç başlıkları altı çizili.
  const headers = [
    ('No.', true),
    ('Pano/tablo numarası-linye adı-etiketi', true),
    ('Açma eğrisi tipi', false),
    ('Kutup sayısı', false),
    ('Kısa devre kesme akımı Icu (kA)', false),
    ('Nominal akım In (A)', false),
    ('Tasarım (yük) akımı Ib (A)', false),
    ('Faz kesiti (mm²)', false),
    ('PE koruma iletkeni kesiti (mm²)', false),
    ('N/PEN kesiti (mm²)', false),
    ('Akım taşıma kapasitesi (Iz) (A)', false),
    ('Açma akımı IΔ (mA)', false),
    ('Açma akımı TΔ (ms)', false),
    ('Sonuç (Not)', true),
  ];

  pw.Widget groupCell(String text, int fromCol, int toCol) {
    final flex = _colFlex.sublist(fromCol, toCol + 1).reduce((a, b) => a + b);
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        height: 12,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(border: pw.Border.all(width: _border)),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: _fsSmall, decoration: pw.TextDecoration.underline)),
      ),
    );
  }

  final rows = <pw.TableRow>[
    pw.TableRow(
      repeat: true,
      children: [
        for (final (h, underline) in headers) _cell(h, underline: underline, size: 6.5, align: pw.TextAlign.center),
      ],
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
    rows.add(pw.TableRow(children: [for (final v in values) _value(v, size: _fsSmall)]));
  }

  return [
    _keep([
      _sectionTitle('6. FONKSİON KONTROL KRİTERLERİ VE TESTLER'),
      ..._kvTable([
        ['Ölçüm ve Doğrulama Metodu', choiceText(ReportTemplate.olcumMetodu, r.method)],
      ]),
      _subTitle('AŞIRI AKIM CİHAZI, İLETKEN UYGUNLUĞU, GERİLİM KONTROLÜ, AŞIRI GERİM CİHAZLARI (DKD) KONTROLÜ VE '
          '(ARTIK AKIM ANAHTARI) RCD TESTLERİ'),
      ..._kvTable(labelBold: true, [
        ['Pano (Ekipman) Adı-Etiketi veya Kodu', orDash(r.panelName)],
      ]),
      ..._kvTable([
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
      pw.Row(children: [
        groupCell('', 0, 1),
        groupCell('Aşırı Akım Koruma Cihazının', 2, 5),
        groupCell('İletkenin', 6, 10),
        groupCell('RCD Testi', 11, 12),
        groupCell('', 13, 13),
      ]),
    ]),
    pw.Table(
      border: pw.TableBorder.all(width: _border),
      columnWidths: {for (var k = 0; k < _colFlex.length; k++) k: pw.FlexColumnWidth(_colFlex[k].toDouble())},
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: rows,
    ),
    _keep([
      _subTitle('ZEMİN İZOLASYONUNUN KONTROLÜ'),
      pw.Table(
        border: pw.TableBorder.all(width: _border),
        defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
        columnWidths: const {
          0: pw.FlexColumnWidth(1),
          1: pw.FlexColumnWidth(6),
          2: pw.FlexColumnWidth(2),
          3: pw.FlexColumnWidth(2),
          4: pw.FlexColumnWidth(3),
          5: pw.FlexColumnWidth(3),
        },
        children: [
          pw.TableRow(children: [
            for (final h in [
              'No.',
              'İzolasyon halısının (zemin yalıtımının) yeri',
              'Eni (m)',
              'Boyu (m)',
              'Zemin izolasyon direnci (kΩ)',
              'Sonuç (Uygunluk notu)',
            ])
              _cell(h, underline: true, align: pw.TextAlign.center),
          ]),
          for (var i = 0; i < r.floorInsulations.length; i++)
            pw.TableRow(children: [
              _value('${i + 1}.'),
              _value(orDash(r.floorInsulations[i].location)),
              _value(orDash(r.floorInsulations[i].widthM)),
              _value(orDash(r.floorInsulations[i].lengthM)),
              _value(orDash(r.floorInsulations[i].resistanceKohm)),
              _value(floorResult(r.floorInsulations[i], p)?.label ?? '-'),
            ]),
        ],
      ),
    ]),
  ];
}

pw.Widget _photos(PanelReport r, pw.MemoryImage? equipment, pw.MemoryImage? thermal) {
  // Fotoğraf yoksa alan küçülür; rapor boş kutular yüzünden sayfa kaybetmez.
  final height = equipment == null && thermal == null ? 30.0 : 210.0;
  pw.Widget slot(String caption, pw.MemoryImage? img) => pw.Expanded(
        child: pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: _border)),
          child: pw.Column(children: [
            _cell(caption, underline: true, align: pw.TextAlign.center),
            pw.Container(
              height: height,
              padding: const pw.EdgeInsets.all(3),
              alignment: pw.Alignment.center,
              child: img == null ? null : pw.Image(img, fit: pw.BoxFit.contain),
            ),
          ]),
        ),
      );
  return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
    slot(orDash(r.panelName), equipment),
    slot('TERMAL FOTOĞRAF', thermal),
  ]);
}

/// 10. bölüm: biçimli sonuç cümlesi ve Word'deki satır düzeniyle ağır kusur tanımları.
List<pw.Widget> _sonuc(PanelReport r, bool uygun) {
  final sentence = pw.RichText(
    textAlign: pw.TextAlign.justify,
    text: pw.TextSpan(children: [
      for (final (text, bold, italic) in ReportTemplate.sonucParcalari(
        uygun: uygun,
        sonrakiTarih: formatDate(r.nextDate),
      ))
        pw.TextSpan(
          text: text,
          style: pw.TextStyle(
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
          ),
        ),
    ]),
  );

  final numbered = RegExp(r'^(\d+\.)\s');
  pw.Widget line(String s) {
    if (s.isEmpty) return pw.SizedBox(height: 5);
    if (s.startsWith('#')) {
      return pw.Text(s.substring(1), style: const pw.TextStyle(fontWeight: pw.FontWeight.bold));
    }
    final m = numbered.firstMatch(s);
    if (m == null) return pw.Text(s);
    return pw.RichText(
      text: pw.TextSpan(children: [
        pw.TextSpan(text: m.group(1), style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.TextSpan(text: s.substring(m.group(1)!.length)),
      ]),
    );
  }

  // Başlık ve sonuç cümlesi birlikte kalır; uzun ağır kusur listesi ise sayfa sonunda satır satır
  // bölünebilir (aksi halde bölüm bütünüyle sonraki sayfaya atlar ve yarım sayfa boş kalır).
  const sides = pw.BorderSide(width: _border);
  pw.TableRow listRow(pw.Widget child) => pw.TableRow(children: [
        pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 3), child: child),
      ]);
  return [
    _keep([
      _sectionTitle('10. SONUÇ VE KANAAT'),
      pw.Container(
        padding: const pw.EdgeInsets.fromLTRB(3, 2, 3, 6),
        decoration: const pw.BoxDecoration(border: pw.Border(left: sides, right: sides)),
        child: sentence,
      ),
    ]),
    pw.Table(
      border: const pw.TableBorder(left: sides, right: sides, bottom: sides),
      children: [
        for (final s in ReportTemplate.agirKusurTanimlari) listRow(line(s)),
        listRow(pw.SizedBox(height: 2)),
      ],
    ),
  ];
}

List<pw.Widget> _yetkili(SiteProfile p) {
  pw.TableRow row(String label, String value) => pw.TableRow(children: [
        _cell(label, bold: true),
        _cell(orDash(value), align: pw.TextAlign.center),
      ]);
  return [
    _keep([
      _sectionTitle('11. PERİYODİK KONTROLLLERİ YAPMAYA YETKİLİ KİŞİ BİLGİLERİ VE ONAY'),
      pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(width: _border)),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(
            flex: 7,
            child: pw.Table(
              border: const pw.TableBorder(
                right: pw.BorderSide(width: _border),
                horizontalInside: pw.BorderSide(width: _border),
                verticalInside: pw.BorderSide(width: _border),
              ),
              columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(5)},
              children: [
                row('Adı Soyadı', p.inspectorName),
                row('Mesleği', p.inspectorProfession),
                row('Diploma Numarası', p.inspectorDiplomaNo),
                row('Ekipnet Kayıt Numarası', p.inspectorEkipnetNo),
              ],
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: _cell('İmzası', bold: true, underline: true, align: pw.TextAlign.center),
          ),
        ]),
      ),
      _box(pw.Text(ReportTemplate.nushaMetni)),
    ]),
  ];
}
