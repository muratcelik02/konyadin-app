import 'package:flutter/material.dart';
import '../report_models.dart';
import '../report_rules.dart';
import '../report_store.dart';
import 'job_screen.dart';

class ReportJobsScreen extends StatefulWidget {
  final ReportStore store;
  const ReportJobsScreen({super.key, required this.store});

  @override
  State<ReportJobsScreen> createState() => _ReportJobsScreenState();
}

class _ReportJobsScreenState extends State<ReportJobsScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.load();
  }

  Future<void> _newJob() async {
    final titleCtrl = TextEditingController();
    InspectionJob? copyFrom = widget.store.jobs.isNotEmpty ? widget.store.jobs.first : null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Yeni Görev'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Görev adı', hintText: 'Örn: KAYSERİ ŞEHİR HASTANESİ 2026'),
            ),
            if (widget.store.jobs.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<InspectionJob?>(
                initialValue: copyFrom,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Firma/cihaz bilgilerini kopyala'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Boş başla')),
                  for (final j in widget.store.jobs)
                    DropdownMenuItem(value: j, child: Text(j.title, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setLocal(() => copyFrom = v),
              ),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oluştur')),
          ],
        ),
      ),
    );
    final title = titleCtrl.text.trim();
    titleCtrl.dispose();
    if (ok != true || title.isEmpty || !mounted) return;
    final job = await widget.store.createJob(title, copyProfileFrom: copyFrom);
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => JobScreen(store: widget.store, job: job)));
  }

  Future<void> _delete(InspectionJob job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Görev silinsin mi?'),
        content: Text('"${job.title}" ve içindeki ${job.reports.length} pano raporu fotoğraflarıyla birlikte '
            'bu telefondan kalıcı olarak silinecek.'),
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
    if (ok == true) await widget.store.deleteJob(job);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final jobs = widget.store.jobs;
        return Scaffold(
          appBar: AppBar(title: const Text('Periyodik Kontrol Raporları')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _newJob,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Görev'),
          ),
          body: widget.store.isLoading && jobs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : jobs.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Henüz görev yok.\nBir tesis için "Yeni Görev" oluşturun; firma ve cihaz bilgilerini bir kez '
                          'girip o tesisteki tüm panoların raporlarını hazırlayın.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                      itemCount: jobs.length,
                      itemBuilder: (context, i) {
                        final job = jobs[i];
                        final drafts = job.reports.where((r) => missingFields(r).isNotEmpty).length;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.business_outlined),
                            title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${job.reports.length} pano'
                                '${drafts > 0 ? ' · $drafts taslak' : ''} · ${formatDate(job.updatedAt)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Görevi sil',
                              onPressed: () => _delete(job),
                            ),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => JobScreen(store: widget.store, job: job)),
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
