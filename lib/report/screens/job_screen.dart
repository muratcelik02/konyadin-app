import 'package:flutter/material.dart';
import '../report_models.dart';
import '../report_rules.dart';
import '../report_store.dart';
import 'panel_screen.dart';
import 'profile_screen.dart';

class JobScreen extends StatefulWidget {
  final ReportStore store;
  final InspectionJob job;
  const JobScreen({super.key, required this.store, required this.job});

  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  InspectionJob get job => widget.job;

  Future<void> _openPanel(PanelReport report) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PanelScreen(store: widget.store, job: job, report: report)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _addPanel({PanelReport? copyOf}) async {
    final report = widget.store.newPanel(job);
    if (copyOf != null) {
      // Aynı tip panolar için devre listesi (ad, koruma, kablo) kopyalanır.
      // Ölçümler, kriterler ve sonuçlar her pano için yeniden girilmelidir.
      report.circuits = [for (final c in copyOf.circuits) c.copyAsTemplate()..name = c.name];
      report.floorInsulations = [
        for (final f in copyOf.floorInsulations) FloorInsulation(widthM: f.widthM, lengthM: f.lengthM),
      ];
    }
    await widget.store.save(job);
    await _openPanel(report);
  }

  Future<void> _deletePanel(PanelReport report) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pano raporu silinsin mi?'),
        content: Text('"${report.panelName.isEmpty ? report.reportNo : report.panelName}" kalıcı olarak silinecek.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await widget.store.deleteMedia(report.equipmentPhotoPath);
    await widget.store.deleteMedia(report.thermalPhotoPath);
    job.reports.remove(report);
    await widget.store.save(job);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profileFilled = job.profile.text('firmaAdi').isNotEmpty && job.profile.inspectorName.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(job.title, overflow: TextOverflow.ellipsis)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPanel(),
        icon: const Icon(Icons.add),
        label: const Text('Pano Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                profileFilled ? Icons.check_circle : Icons.info_outline,
                color: profileFilled ? Colors.green : Colors.orange,
              ),
              title:
                  const Text('Tesis, firma, cihaz ve yetkili bilgileri', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(profileFilled
                  ? job.profile.text('firmaAdi')
                  : 'Tüm pano raporlarında ortak bilgiler. Önce burayı doldurun.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProfileScreen(store: widget.store, job: job)),
                );
                if (mounted) setState(() {});
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Panolar (${job.reports.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          if (job.reports.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Henüz pano yok. "Pano Ekle" ile başlayın.', textAlign: TextAlign.center),
            ),
          for (final r in job.reports) _panelTile(r),
        ],
      ),
    );
  }

  Widget _panelTile(PanelReport r) {
    final missing = missingFields(r);
    final uygun = conclusion(r, job.profile);
    final color = missing.isNotEmpty ? Colors.orange : (uygun ? Colors.green : Colors.red);
    final status = missing.isNotEmpty ? 'TASLAK · ${missing.length} eksik' : (uygun ? 'UYGUNDUR' : 'UYGUN DEĞİLDİR');
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.electrical_services, color: color),
        ),
        title: Text(r.panelName.isEmpty ? '(pano adı yok)' : r.panelName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${r.reportNo} · ${r.circuits.length} devre\n$status', style: TextStyle(color: color.shade700)),
        isThreeLine: true,
        onTap: () => _openPanel(r),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'copy') _addPanel(copyOf: r);
            if (v == 'delete') _deletePanel(r);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'copy', child: Text('Devre listesini yeni panoya kopyala')),
            PopupMenuItem(value: 'delete', child: Text('Sil')),
          ],
        ),
      ),
    );
  }
}
