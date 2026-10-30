import 'dart:async';
import 'package:flutter/material.dart';
import '../report_models.dart';
import '../report_rules.dart';
import '../report_store.dart';
import '../report_template.dart';

/// Değişiklikleri kısa bir gecikmeyle diske yazar; ekran kapanırken bekleyen kaydı hemen yapar.
/// Sahada uygulama kapansa bile en fazla son birkaç saniyelik giriş kaybolur.
mixin AutoSave<T extends StatefulWidget> on State<T> {
  ReportStore get store;
  InspectionJob get job;
  Timer? _saveTimer;

  void changed() {
    setState(() {});
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () => store.save(job));
  }

  Future<void> saveNow() async {
    _saveTimer?.cancel();
    await store.save(job);
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      store.save(job);
    }
    super.dispose();
  }
}

const numberKeyboard = TextInputType.numberWithOptions(decimal: true, signed: true);

/// Kendi denetleyicisini tutan metin alanı: üst ekran her tuşta yeniden çizilse de imleç kaymaz.
class BoundTextField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final String? hint;
  final int maxLines;
  final bool dense;

  const BoundTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
    this.hint,
    this.maxLines = 1,
    this.dense = false,
  });

  @override
  State<BoundTextField> createState() => _BoundTextFieldState();
}

class _BoundTextFieldState extends State<BoundTextField> {
  late final TextEditingController _c = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(BoundTextField old) {
    super.didUpdateWidget(old);
    // Değer dışarıdan değiştiyse (ör. "kopyala") alana yansıt.
    if (widget.value != _c.text) _c.text = widget.value;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.dense ? 8 : 12),
      child: TextField(
        controller: _c,
        keyboardType: widget.maxLines > 1 ? TextInputType.multiline : widget.keyboardType,
        maxLines: widget.maxLines,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          isDense: widget.dense,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

Color evaluationColor(Evaluation? e) {
  switch (e) {
    case Evaluation.uygun:
      return const Color(0xFF10B981);
    case Evaluation.uygunDegil:
      return const Color(0xFFEF4444);
    case Evaluation.uygulanamaz:
      return const Color(0xFF64748B);
    case null:
      return const Color(0xFFF59E0B);
  }
}

/// UYGUN / UYGUN DEĞİL / UYGULANAMAZ seçimi. allowAuto: "Otomatik" (kural önerisi) seçeneği.
class EvaluationSelector extends StatelessWidget {
  final Evaluation? value;
  final ValueChanged<Evaluation?> onChanged;
  final bool allowAuto;
  final Evaluation? suggested;

  const EvaluationSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowAuto = false,
    this.suggested,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, Evaluation? e, {bool selected = false}) => ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          selected: selected,
          selectedColor: evaluationColor(e).withValues(alpha: 0.25),
          visualDensity: VisualDensity.compact,
          onSelected: (_) => onChanged(selected && !allowAuto ? null : e),
        );
    return Wrap(spacing: 6, runSpacing: 4, children: [
      if (allowAuto)
        chip('Otomatik${suggested != null ? ' (${suggested!.label})' : ''}', null, selected: value == null),
      for (final e in Evaluation.values) chip(e.label, e, selected: value == e),
    ]);
  }
}

/// Şablondaki ○/● seçim alanı.
class ChoiceSelector extends StatelessWidget {
  final ChoiceFieldDef def;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const ChoiceSelector({super.key, required this.def, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(def.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Wrap(spacing: 6, runSpacing: 4, children: [
          for (final o in def.options)
            FilterChip(
              label: Text(o, style: const TextStyle(fontSize: 12)),
              selected: selected.contains(o),
              visualDensity: VisualDensity.compact,
              onSelected: (on) {
                final next = def.multi ? List.of(selected) : <String>[];
                if (on) {
                  next.add(o);
                } else {
                  next.remove(o);
                }
                onChanged(next);
              },
            ),
        ]),
      ]),
    );
  }
}

class DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool withTime;
  final ValueChanged<DateTime?> onChanged;

  const DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.withTime = true,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (d == null || !context.mounted) return;
    if (!withTime) {
      onChanged(DateTime(d.year, d.month, d.day));
      return;
    }
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value ?? now),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null) return;
    onChanged(DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.event)),
          child: Text(withTime ? formatDateTime(value) : formatDate(value)),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Widget? leading;

  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.initiallyExpanded = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: leading,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(fontSize: 12)),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
