import 'package:flutter/material.dart';
import '../report_models.dart';
import '../report_rules.dart';
import '../report_store.dart';
import '../report_template.dart';
import 'report_widgets.dart';

const _phaseSections = [
  '1X1X1,5',
  '1X1X2,5',
  '1X1X4',
  '1X1X6',
  '1X3X2,5',
  '1X3X4',
  '1X3X6',
  '1X3X10',
  '1X3X16',
  '1X3X25',
  '1X3X35'
];
const _conductorSections = ['1X1,5', '1X2,5', '1X4', '1X6', '1X10', '1X16', '1X25', '1X35'];

/// Fonksiyon test tablosunun tek satırını düzenler. index null ise yeni devre ekler.
class CircuitScreen extends StatefulWidget {
  final ReportStore store;
  final InspectionJob job;
  final PanelReport report;
  final int? index;

  const CircuitScreen({super.key, required this.store, required this.job, required this.report, this.index});

  @override
  State<CircuitScreen> createState() => _CircuitScreenState();
}

class _CircuitScreenState extends State<CircuitScreen> with AutoSave {
  @override
  ReportStore get store => widget.store;
  @override
  InspectionJob get job => widget.job;
  PanelReport get r => widget.report;

  late int _index;
  late Circuit c;
  // Formu yeniden kurmak için: "sonraki devre"ye geçince alanlar yeni değerlerle açılır.
  int _formGeneration = 0;

  @override
  void initState() {
    super.initState();
    if (widget.index != null) {
      _index = widget.index!;
      c = r.circuits[_index];
    } else {
      _appendNew();
    }
  }

  /// Yeni devre son devrenin koruma/kablo bilgileriyle başlar; ölçümler boş gelir.
  void _appendNew() {
    final prev = r.circuits.isNotEmpty ? r.circuits.last : null;
    c = prev?.copyAsTemplate() ?? Circuit();
    r.circuits.add(c);
    _index = r.circuits.length - 1;
  }

  @override
  void dispose() {
    // Açılıp hiçbir şey yazılmadan bırakılan yeni devre tabloda boş satır bırakmasın.
    final untouched = [c.name, c.ibA, c.idnMa, c.tdMs, c.note].every((v) => !isFilled(v));
    if (untouched && (widget.index == null || _index != widget.index)) {
      r.circuits.remove(c);
      store.save(job);
    }
    super.dispose();
  }

  void _set(void Function() apply) {
    apply();
    r.updatedAt = DateTime.now();
    changed();
  }

  Future<void> _next() async {
    await saveNow();
    setState(() {
      _appendNew();
      _formGeneration++;
    });
    await saveNow();
  }

  String? _izSuggestion() {
    if (isFilled(c.izA) || !isFilled(c.phaseSection)) return null;
    for (final o in r.circuits) {
      if (!identical(o, c) && o.phaseSection.trim() == c.phaseSection.trim() && isFilled(o.izA)) return o.izA;
    }
    return null;
  }

  Widget _quickChips(List<String> options, String current, ValueChanged<String> onPick) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Wrap(spacing: 6, runSpacing: 4, children: [
          for (final o in options)
            ChoiceChip(
              label: Text(o, style: const TextStyle(fontSize: 12)),
              selected: current.trim() == o,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onPick(o),
            ),
        ]),
      );

  Widget _f(String label, String value, ValueChanged<String> set, {bool number = true, String? hint}) => BoundTextField(
        label: label,
        hint: hint,
        value: value,
        keyboardType: number ? numberKeyboard : null,
        onChanged: (v) => _set(() => set(v)),
      );

  @override
  Widget build(BuildContext context) {
    final check = checkCircuit(c, profile: job.profile, panelIkKa: r.ikKa);
    final izHint = _izSuggestion();

    return Scaffold(
      appBar: AppBar(title: Text('${_index + 1}. Devre')),
      body: ListView(
        key: ValueKey(_formGeneration),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _f('Linye adı / etiketi', c.name, (v) => c.name = v, number: false, hint: 'P1 PRİZ+HAV.'),
          const Text('Aşırı akım koruma cihazı', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _f('Açma eğrisi tipi', c.curve, (v) => c.curve = v, number: false),
          _quickChips(ReportTemplate.curveOptions, c.curve, (v) => _set(() => c.curve = v)),
          Row(children: [
            Expanded(child: _f('Kutup sayısı', c.poles, (v) => c.poles = v)),
            const SizedBox(width: 8),
            Expanded(child: _f('Icu (kA)', c.icuKa, (v) => c.icuKa = v)),
            const SizedBox(width: 8),
            Expanded(child: _f('In (A)', c.inA, (v) => c.inA = v)),
          ]),
          _quickChips(ReportTemplate.poleOptions, c.poles, (v) => _set(() => c.poles = v)),
          const Text('İletken', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _f('Tasarım (yük) akımı Ib (A) — ölçüm', c.ibA, (v) => c.ibA = v),
          _f('Faz kesiti (mm²)', c.phaseSection, (v) => c.phaseSection = v, number: false, hint: '1X1X2,5'),
          _quickChips(_phaseSections, c.phaseSection, (v) => _set(() => c.phaseSection = v)),
          Row(children: [
            Expanded(child: _f('PE kesiti (mm²)', c.peSection, (v) => c.peSection = v, number: false)),
            const SizedBox(width: 8),
            Expanded(child: _f('N/PEN kesiti (mm²)', c.nSection, (v) => c.nSection = v, number: false)),
          ]),
          _quickChips(
              _conductorSections,
              c.peSection,
              (v) => _set(() {
                    c.peSection = v;
                    c.nSection = v;
                  })),
          _f('Akım taşıma kapasitesi Iz (A)', c.izA, (v) => c.izA = v),
          if (izHint != null)
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.lightbulb_outline, size: 18),
                label: Text('Aynı kesitli devreden: Iz = $izHint A'),
                onPressed: () => _set(() => c.izA = izHint),
              ),
            ),
          const SizedBox(height: 8),
          const Text('RCD testi — ölçüm', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _f('Açma akımı IΔ (mA)', c.idnMa, (v) => c.idnMa = v, hint: 'RCD yoksa -')),
            const SizedBox(width: 8),
            Expanded(child: _f('Açma süresi TΔ (ms)', c.tdMs, (v) => c.tdMs = v, hint: 'RCD yoksa -')),
          ]),
          _issues(check),
          const SizedBox(height: 4),
          const Text('Sonuç', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          EvaluationSelector(
            value: c.resultOverride,
            allowAuto: true,
            suggested: check.suggested,
            onChanged: (e) => _set(() => c.resultOverride = e),
          ),
          const SizedBox(height: 10),
          _f('Not (sonuç sütununa eklenir)', c.note, (v) => c.note = v, number: false),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.playlist_add),
            label: const Text('Kaydet ve sonraki devre'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              await saveNow();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Kaydet ve kapat'),
          ),
        ],
      ),
    );
  }

  Widget _issues(CircuitCheck check) {
    if (check.issues.isEmpty) {
      if (check.suggested == null) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Ib, In ve Iz girilince kurallar kontrol edilir.',
              style: TextStyle(fontSize: 12, color: Colors.black54)),
        );
      }
      return Card(
        color: Colors.green.shade50,
        child: const ListTile(
          dense: true,
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('Kural kontrolleri geçti (Ib ≤ In ≤ Iz, Icu ≥ Ik, RCD, PE/N)'),
        ),
      );
    }
    return Card(
      color: check.suggested == Evaluation.uygunDegil ? Colors.red.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final i in check.issues)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(i.level == IssueLevel.fail ? Icons.error : Icons.warning_amber_rounded,
                    size: 18, color: i.level == IssueLevel.fail ? Colors.red : Colors.orange),
                const SizedBox(width: 6),
                Expanded(child: Text(i.message, style: const TextStyle(fontSize: 13))),
              ]),
            ),
        ]),
      ),
    );
  }
}
