import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../report_models.dart';
import '../report_rules.dart';
import '../report_store.dart';
import '../report_template.dart';
import 'circuit_screen.dart';
import 'report_pdf_screen.dart';
import 'report_widgets.dart';

class PanelScreen extends StatefulWidget {
  final ReportStore store;
  final InspectionJob job;
  final PanelReport report;
  const PanelScreen({super.key, required this.store, required this.job, required this.report});

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> with AutoSave {
  @override
  ReportStore get store => widget.store;
  @override
  InspectionJob get job => widget.job;
  PanelReport get r => widget.report;
  SiteProfile get profile => job.profile;

  Uint8List? _equipmentPhoto;
  Uint8List? _thermalPhoto;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final e = await store.readMedia(r.equipmentPhotoPath);
    final t = await store.readMedia(r.thermalPhotoPath);
    if (mounted) {
      setState(() {
        _equipmentPhoto = e;
        _thermalPhoto = t;
      });
    }
  }

  @override
  void changed() {
    r.updatedAt = DateTime.now();
    super.changed();
  }

  Future<void> _pickPhoto({required bool thermal}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Kamera ile çek'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text(thermal ? 'Galeriden seç (termal kamera görüntüsü)' : 'Galeriden seç'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;
    final x = await ImagePicker().pickImage(source: source, maxWidth: kIsWeb ? 1000 : 1600, imageQuality: 80);
    if (x == null) return;
    final rel = await store.importMedia(job, x);
    if (thermal) {
      await store.deleteMedia(r.thermalPhotoPath);
      r.thermalPhotoPath = rel;
    } else {
      await store.deleteMedia(r.equipmentPhotoPath);
      r.equipmentPhotoPath = rel;
    }
    await _loadPhotos();
    changed();
  }

  /// Kriterleri UYGUN yapar. Teknisyenin bilerek UYGUN DEĞİL / UYGULANAMAZ işaretledikleri
  /// sessizce ezilmesin diye önce sorulur.
  Future<void> _markAllUygun(List<CriterionDef> items) async {
    final others = items.where((c) {
      final e = r.criteria[c.id];
      return e != null && e != Evaluation.uygun;
    }).toList();
    var overwrite = false;
    if (others.isNotEmpty) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Farklı işaretli kriterler var'),
          content: Text('${others.length} kriter UYGUN DEĞİL veya UYGULANAMAZ işaretli:\n\n'
              '${others.map((c) => '• ${c.label} (${r.criteria[c.id]!.label})').join('\n')}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'all'), child: const Text('Hepsini UYGUN yap')),
            TextButton(onPressed: () => Navigator.pop(ctx, 'empty'), child: const Text('Onlara dokunma')),
          ],
        ),
      );
      if (choice == null) return;
      overwrite = choice == 'all';
    }
    for (final c in items) {
      if (overwrite) {
        r.criteria[c.id] = Evaluation.uygun;
      } else {
        r.criteria.putIfAbsent(c.id, () => Evaluation.uygun);
      }
    }
    changed();
  }

  Future<void> _openCircuit(int? index) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CircuitScreen(store: store, job: job, report: r, index: index),
    ));
    if (mounted) setState(() {});
  }

  Future<void> _openPdf() async {
    await saveNow();
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReportPdfScreen(store: store, job: job, report: r),
    ));
  }

  Widget _field(String label, String value, ValueChanged<String> set, {bool number = true, String? hint}) =>
      BoundTextField(
        label: label,
        hint: hint,
        value: value,
        keyboardType: number ? numberKeyboard : null,
        onChanged: (v) {
          set(v);
          changed();
        },
      );

  @override
  Widget build(BuildContext context) {
    final missing = missingFields(r);
    final evaluated = ReportTemplate.allCriteria.where((c) => r.criteria.containsKey(c.id)).length;
    final total = ReportTemplate.allCriteria.length;
    final suggested = suggestedConclusion(r, profile);

    return Scaffold(
      appBar: AppBar(
        title: Text(r.panelName.isEmpty ? 'Yeni Pano' : r.panelName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: 'PDF', onPressed: _openPdf),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 40),
        children: [
          _missingCard(missing),
          SectionCard(
            title: 'Genel',
            subtitle: '${orDash(r.reportNo)} · ${formatDateTime(r.start)}',
            initiallyExpanded: r.panelName.isEmpty,
            children: [
              _field('Pano Adı / Ekipman Tanımlaması', r.panelName, (v) => r.panelName = v, number: false),
              _field('Rapor Numarası', r.reportNo, (v) => r.reportNo = v, number: false),
              DateTimeField(
                label: 'Başlangıç tarihi ve saati',
                value: r.start,
                onChanged: (v) {
                  r.start = v;
                  if (v != null) {
                    r.end = v.add(Duration(minutes: profile.minutesPerPanel));
                    r.reportDate = DateTime(v.year, v.month, v.day);
                    r.nextDate = DateTime(v.year + 1, v.month, v.day);
                  }
                  changed();
                },
              ),
              DateTimeField(
                  label: 'Bitiş tarihi ve saati',
                  value: r.end,
                  onChanged: (v) {
                    r.end = v;
                    changed();
                  }),
              DateTimeField(
                  label: 'Rapor tarihi',
                  value: r.reportDate,
                  withTime: false,
                  onChanged: (v) {
                    r.reportDate = v;
                    changed();
                  }),
              DateTimeField(
                  label: 'Bir sonraki periyodik kontrol',
                  value: r.nextDate,
                  withTime: false,
                  onChanged: (v) {
                    r.nextDate = v;
                    changed();
                  }),
            ],
          ),
          SectionCard(
            title: '5. Kontrol Kriterleri',
            subtitle: '$evaluated / $total değerlendirildi',
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.done_all),
                label: const Text('Tümünü UYGUN yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  minimumSize: const Size.fromHeight(46),
                ),
                onPressed: () => _markAllUygun(ReportTemplate.allCriteria),
              ),
              const SizedBox(height: 4),
              for (final g in ReportTemplate.criteriaGroups) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(g.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E5BB0))),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _markAllUygun(g.items),
                      child: const Text('Grubu UYGUN', style: TextStyle(fontSize: 12)),
                    ),
                  ]),
                ),
                for (final c in g.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.label, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      EvaluationSelector(
                        value: r.criteria[c.id],
                        onChanged: (e) {
                          if (e == null) {
                            r.criteria.remove(c.id);
                          } else {
                            r.criteria[c.id] = e;
                          }
                          changed();
                        },
                      ),
                    ]),
                  ),
              ],
            ],
          ),
          SectionCard(
            title: 'Termal Kamera',
            subtitle: r.thermalPhotoPath == null ? 'Termal fotoğraf yok' : 'Termal fotoğraf eklendi',
            children: [
              _field('Fotoğraf numarası', r.thermalPhotoNo, (v) => r.thermalPhotoNo = v,
                  number: false, hint: 'IMG_0020'),
              _field('Fotoğraf tarihi', r.thermalPhotoDate, (v) => r.thermalPhotoDate = v,
                  number: false, hint: '01.09.2026'),
              _photoSlot('Termal fotoğraf', _thermalPhoto, () => _pickPhoto(thermal: true)),
            ],
          ),
          SectionCard(
            title: '6. Ölçümler',
            subtitle: 'Çevrim empedansı, gerilimler, Ik, DKD',
            children: [
              ChoiceSelector(
                def: ReportTemplate.olcumMetodu,
                selected: r.method,
                onChanged: (v) {
                  r.method = v;
                  changed();
                },
              ),
              _field('Faz-nötr çevrim empedansı ZLN (Ω)', r.zlnOhm, (v) => r.zlnOhm = v),
              _field('Faz-toprak çevrim empedansı Zx (Ω)', r.zxOhm, (v) => r.zxOhm = v),
              Row(children: [
                Expanded(child: _field('F-F (V)', r.vff, (v) => r.vff = v)),
                const SizedBox(width: 8),
                Expanded(child: _field('L-N (V)', r.vln, (v) => r.vln = v)),
                const SizedBox(width: 8),
                Expanded(child: _field('N-PE (V)', r.vnpe, (v) => r.vnpe = v)),
              ]),
              _field('Hesaplanan 3 fazlı kısa devre akımı Ik (kA)', r.ikKa, (v) => r.ikKa = v),
              _field('Aşırı gerilim koruma (DKD) tipi', r.spdType, (v) => r.spdType = v,
                  number: false, hint: 'UYGULANAMAZ / TİP 2 ...'),
              _field('DKD dayanma akımı (kA)', r.spdKa, (v) => r.spdKa = v, number: false, hint: 'UYGULANAMAZ / 40'),
            ],
          ),
          _circuitsCard(),
          _floorCard(),
          SectionCard(
            title: '7. Kusur Açıklamaları',
            subtitle: r.defects.trim().isEmpty ? 'Kusur yok' : r.defects.trim().split('\n').first,
            children: [
              BoundTextField(
                label: 'Kusurlar (her satıra bir kusur; ağır kusur için ** kullanın)',
                value: r.defects,
                maxLines: 5,
                onChanged: (v) {
                  r.defects = v;
                  changed();
                },
              ),
            ],
          ),
          SectionCard(
            title: '8. Ekipman Fotoğrafı',
            subtitle: r.equipmentPhotoPath == null ? 'Fotoğraf yok' : 'Fotoğraf eklendi',
            children: [_photoSlot('Pano fotoğrafı', _equipmentPhoto, () => _pickPhoto(thermal: false))],
          ),
          SectionCard(
            title: '10. Sonuç ve Kanaat',
            subtitle: conclusion(r, profile) ? 'UYGUNDUR' : 'UYGUN DEĞİLDİR',
            children: [
              Wrap(spacing: 6, children: [
                ChoiceChip(
                  label: Text('Otomatik (${suggested ? 'UYGUNDUR' : 'UYGUN DEĞİLDİR'})'),
                  selected: r.conclusionOverride == null,
                  onSelected: (_) {
                    r.conclusionOverride = null;
                    changed();
                  },
                ),
                ChoiceChip(
                  label: const Text('UYGUNDUR'),
                  selected: r.conclusionOverride == true,
                  onSelected: (_) {
                    r.conclusionOverride = true;
                    changed();
                  },
                ),
                ChoiceChip(
                  label: const Text('UYGUN DEĞİLDİR'),
                  selected: r.conclusionOverride == false,
                  onSelected: (_) {
                    r.conclusionOverride = false;
                    changed();
                  },
                ),
              ]),
              const SizedBox(height: 8),
              const Text(
                'Otomatik: herhangi bir kriter, devre veya zemin ölçümü UYGUN DEĞİL ise sonuç UYGUN DEĞİLDİR olur.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _openPdf,
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(missing.isEmpty ? 'PDF Oluştur' : 'Taslak PDF Oluştur'),
          ),
        ],
      ),
    );
  }

  Widget _missingCard(List<String> missing) {
    if (missing.isEmpty) {
      return Card(
        color: Colors.green.withValues(alpha: 0.15),
        child: const ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('Rapor tamamlandı'),
          subtitle: Text('Tüm zorunlu alanlar dolu. Bilinmeyen değerler için "-" girildi.'),
        ),
      );
    }
    return Card(
      color: Colors.orange.withValues(alpha: 0.15),
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: Text('Taslak · ${missing.length} eksik'),
        subtitle: const Text('Eksikler tamamlanana kadar PDF "TASLAK" damgalı çıkar.', style: TextStyle(fontSize: 12)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final m in missing) Text('• $m', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          const Text('Bilinmeyen değer için alana "-" yazın.', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _circuitsCard() {
    final failing =
        r.circuits.where((c) => circuitResult(c, profile: profile, panelIkKa: r.ikKa) == Evaluation.uygunDegil).length;
    return SectionCard(
      title: 'Fonksiyon Test Tablosu',
      subtitle: '${r.circuits.length} devre${failing > 0 ? ' · $failing UYGUN DEĞİL' : ''}',
      initiallyExpanded: true,
      children: [
        for (var i = 0; i < r.circuits.length; i++) _circuitTile(i),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => _openCircuit(null),
          icon: const Icon(Icons.add),
          label: const Text('Devre ekle'),
        ),
      ],
    );
  }

  Widget _circuitTile(int i) {
    final c = r.circuits[i];
    final result = circuitResult(c, profile: profile, panelIkKa: r.ikKa);
    final color = evaluationColor(result);
    return Dismissible(
      key: ObjectKey(c),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade100,
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${i + 1}. devre silinsin mi?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
          ],
        ),
      ),
      onDismissed: (_) {
        r.circuits.removeAt(i);
        changed();
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        dense: true,
        leading: CircleAvatar(
          radius: 15,
          backgroundColor: color.withValues(alpha: 0.18),
          child: Text('${i + 1}', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(c.name.isEmpty ? '(isimsiz devre)' : c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${orDash(c.curve)}${orDash(c.inA)} A · ${orDash(c.phaseSection)} mm² · Ib ${orDash(c.ibA)} · '
          'IΔ ${orDash(c.idnMa)} / TΔ ${orDash(c.tdMs)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing:
            Text(result?.label ?? 'EKSİK', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        onTap: () => _openCircuit(i),
      ),
    );
  }

  Widget _floorCard() {
    return SectionCard(
      title: 'Zemin İzolasyonu',
      subtitle: '${r.floorInsulations.length} ölçüm',
      children: [
        for (var i = 0; i < r.floorInsulations.length; i++) _floorRow(i),
        OutlinedButton.icon(
          onPressed: () {
            r.floorInsulations.add(FloorInsulation(location: r.panelName.isEmpty ? '' : '${r.panelName} ÖNÜ'));
            changed();
          },
          icon: const Icon(Icons.add),
          label: const Text('Zemin ölçümü ekle'),
        ),
      ],
    );
  }

  Widget _floorRow(int i) {
    final f = r.floorInsulations[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('${i + 1}. ölçüm', style: const TextStyle(fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              r.floorInsulations.removeAt(i);
              changed();
            },
          ),
        ]),
        BoundTextField(
            key: ObjectKey(f),
            label: 'İzolasyon halısının yeri',
            value: f.location,
            dense: true,
            onChanged: (v) {
              f.location = v;
              changed();
            }),
        Row(children: [
          Expanded(
              child: BoundTextField(
                  label: 'Eni (m)',
                  value: f.widthM,
                  dense: true,
                  keyboardType: numberKeyboard,
                  onChanged: (v) {
                    f.widthM = v;
                    changed();
                  })),
          const SizedBox(width: 8),
          Expanded(
              child: BoundTextField(
                  label: 'Boyu (m)',
                  value: f.lengthM,
                  dense: true,
                  keyboardType: numberKeyboard,
                  onChanged: (v) {
                    f.lengthM = v;
                    changed();
                  })),
          const SizedBox(width: 8),
          Expanded(
              child: BoundTextField(
                  label: 'Direnç (kΩ)',
                  value: f.resistanceKohm,
                  dense: true,
                  keyboardType: numberKeyboard,
                  onChanged: (v) {
                    f.resistanceKohm = v;
                    changed();
                  })),
        ]),
        EvaluationSelector(
          value: f.resultOverride,
          allowAuto: true,
          suggested: floorSuggested(f, profile),
          onChanged: (e) {
            f.resultOverride = e;
            changed();
          },
        ),
        const SizedBox(height: 6),
      ]),
    );
  }

  Widget _photoSlot(String label, Uint8List? file, VoidCallback onPick) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (file != null)
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(file, height: 200, fit: BoxFit.cover),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: Text(file == null ? '$label ekle' : '$label değiştir'),
      ),
    ]);
  }
}
