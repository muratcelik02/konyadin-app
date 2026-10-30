import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../report_models.dart';
import '../report_rules.dart';
import '../report_store.dart';
import '../report_template.dart';
import 'report_widgets.dart';

/// Görevdeki tüm pano raporlarında ortak bilgiler: rapor bölüm 1-4, 11 ve ayarlar.
class ProfileScreen extends StatefulWidget {
  final ReportStore store;
  final InspectionJob job;
  const ProfileScreen({super.key, required this.store, required this.job});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with AutoSave {
  @override
  ReportStore get store => widget.store;
  @override
  InspectionJob get job => widget.job;
  SiteProfile get p => job.profile;

  File? _logo;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    final f = await store.resolveMedia(p.logoPath);
    if (mounted) setState(() => _logo = f);
  }

  Future<void> _pickLogo() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (x == null) return;
    p.logoPath = await store.importLogo(x.path);
    await _loadLogo();
    changed();
  }

  Widget _text(TextFieldDef d) => BoundTextField(
        label: d.label,
        hint: d.hint,
        value: p.text(d.id),
        onChanged: (v) {
          p.texts[d.id] = v;
          changed();
        },
      );

  Widget _choice(ChoiceFieldDef d) => ChoiceSelector(
        def: d,
        selected: p.choice(d.id),
        onChanged: (v) {
          p.choices[d.id] = v;
          changed();
        },
      );

  Widget _device(String title, MeasuringDevice d) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        BoundTextField(
            label: 'Cihaz Adı',
            value: d.name,
            dense: true,
            onChanged: (v) {
              d.name = v;
              changed();
            }),
        BoundTextField(
            label: 'Kalibrasyon Tarihi',
            value: d.calibrationDate,
            dense: true,
            onChanged: (v) {
              d.calibrationDate = v;
              changed();
            }),
        BoundTextField(
            label: 'Kalibrasyon Geçerlilik Tarihi',
            hint: '1 YIL / 03.06.2027',
            value: d.validity,
            dense: true,
            onChanged: (v) {
              d.validity = v;
              changed();
            }),
        BoundTextField(
            label: 'Seri Numarası',
            value: d.serialNo,
            dense: true,
            onChanged: (v) {
              d.serialNo = v;
              changed();
            }),
        BoundTextField(
            label: 'Kalibrasyon Numarası',
            value: d.calibrationNo,
            dense: true,
            onChanged: (v) {
              d.calibrationNo = v;
              changed();
            }),
        const Divider(),
      ]);

  String _num(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString().replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tesis ve Firma Bilgileri')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          SectionCard(
            title: '1. Firma Bilgileri',
            initiallyExpanded: true,
            children: [for (final d in ReportTemplate.firmaFields) _text(d)],
          ),
          SectionCard(
            title: '2. Ekipman Bilgileri',
            children: [
              _choice(ReportTemplate.yapiCinsi),
              _choice(ReportTemplate.topraklayiciTipi),
              _choice(ReportTemplate.projeVar),
              _choice(ReportTemplate.kontrolNedeni),
              _choice(ReportTemplate.tekHatVar),
              _choice(ReportTemplate.fazIletken),
              _choice(ReportTemplate.sebekeTipi),
              for (final d in ReportTemplate.ekipmanFields) _text(d),
              _choice(ReportTemplate.dokunmaOnlemleri),
              _choice(ReportTemplate.oncekiEtiket),
              _choice(ReportTemplate.kapsamliDegisiklik),
              _choice(ReportTemplate.spdVar),
            ],
          ),
          SectionCard(
            title: '3. Termal Kamera Bilgileri',
            children: [
              for (var i = 0; i < p.thermalDevices.length; i++) _device('Termal kamera ${i + 1}', p.thermalDevices[i]),
            ],
          ),
          SectionCard(
            title: '4. Ölçüm Aletleri Bilgileri',
            children: [
              for (var i = 0; i < p.measuringDevices.length; i++)
                _device('Ölçüm aleti ${i + 1}', p.measuringDevices[i]),
            ],
          ),
          SectionCard(
            title: '11. Yetkili Kişi',
            children: [
              BoundTextField(
                  label: 'Adı Soyadı',
                  value: p.inspectorName,
                  onChanged: (v) {
                    p.inspectorName = v;
                    changed();
                  }),
              BoundTextField(
                  label: 'Mesleği',
                  value: p.inspectorProfession,
                  onChanged: (v) {
                    p.inspectorProfession = v;
                    changed();
                  }),
              BoundTextField(
                  label: 'Diploma Numarası',
                  value: p.inspectorDiplomaNo,
                  onChanged: (v) {
                    p.inspectorDiplomaNo = v;
                    changed();
                  }),
              BoundTextField(
                  label: 'Ekipnet Kayıt Numarası',
                  value: p.inspectorEkipnetNo,
                  onChanged: (v) {
                    p.inspectorEkipnetNo = v;
                    changed();
                  }),
            ],
          ),
          SectionCard(
            title: 'Rapor Ayarları',
            subtitle: 'Logo, rapor numarası, süre ve kural eşikleri',
            children: [
              Row(children: [
                Container(
                  width: 96,
                  height: 48,
                  decoration:
                      BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
                  child: _logo == null ? const Icon(Icons.image_outlined) : Image.file(_logo!, fit: BoxFit.contain),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(onPressed: _pickLogo, child: const Text('Rapor logosu seç')),
                ),
              ]),
              const SizedBox(height: 12),
              BoundTextField(
                label: 'Kontrol firmasının ekli hali (altbilgi)',
                hint: 'DİNAMİK MÜHENDİSLİK’in',
                value: p.kontrolFirmasiEkli,
                onChanged: (v) {
                  p.kontrolFirmasiEkli = v;
                  changed();
                },
              ),
              Row(children: [
                Expanded(
                  child: BoundTextField(
                    label: 'Rapor no ön eki',
                    value: p.reportNoPrefix,
                    onChanged: (v) {
                      p.reportNoPrefix = v;
                      changed();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BoundTextField(
                    label: 'Sıradaki rapor no',
                    value: p.nextReportNo.toString(),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v.trim());
                      if (n != null) {
                        p.nextReportNo = n;
                        changed();
                      }
                    },
                  ),
                ),
              ]),
              BoundTextField(
                label: 'Pano başına kontrol süresi (dakika)',
                value: p.minutesPerPanel.toString(),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final n = int.tryParse(v.trim());
                  if (n != null && n > 0) {
                    p.minutesPerPanel = n;
                    changed();
                  }
                },
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Kural eşikleri', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              BoundTextField(
                label: 'RCD anma hassasiyeti IΔn (mA)',
                value: _num(p.rcdRatedMa),
                keyboardType: numberKeyboard,
                onChanged: (v) {
                  final n = parseTrNumber(v);
                  if (n != null) {
                    p.rcdRatedMa = n;
                    changed();
                  }
                },
              ),
              BoundTextField(
                label: 'RCD en uzun açma süresi (ms)',
                value: _num(p.rcdMaxMs),
                keyboardType: numberKeyboard,
                onChanged: (v) {
                  final n = parseTrNumber(v);
                  if (n != null) {
                    p.rcdMaxMs = n;
                    changed();
                  }
                },
              ),
              BoundTextField(
                label: 'Zemin izolasyonu en düşük direnç (kΩ)',
                value: _num(p.floorMinKohm),
                keyboardType: numberKeyboard,
                onChanged: (v) {
                  final n = parseTrNumber(v);
                  if (n != null) {
                    p.floorMinKohm = n;
                    changed();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
