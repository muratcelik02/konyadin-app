import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'report_models.dart';

/// Görevleri telefonda (çevrimdışı) JSON dosyaları olarak saklar.
/// Her görev: <belgeler>/reports/<id>.json, fotoğrafları: <belgeler>/reports/<id>/media/.
/// Fotoğraf yolları göreli tutulur; iOS'ta uygulama klasörünün tam yolu güncellemelerde değişebilir.
class ReportStore extends ChangeNotifier {
  final _uuid = const Uuid();
  List<InspectionJob> jobs = [];
  bool isLoading = false;
  Directory? _docs;

  /// docsDir yalnızca testler için; uygulamada telefonun belge klasörü kullanılır.
  ReportStore({Directory? docsDir}) : _docs = docsDir;

  Future<Directory> _docsDir() async => _docs ??= await getApplicationDocumentsDirectory();

  Future<Directory> _reportsDir() async {
    final dir = Directory(p.join((await _docsDir()).path, 'reports'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final loaded = <InspectionJob>[];
    try {
      final dir = await _reportsDir();
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final map = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
            loaded.add(InspectionJob.fromJson(map));
          } catch (e) {
            debugPrint('Görev okunamadı: ${entity.path}: $e');
          }
        }
      }
    } finally {
      loaded.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      jobs = loaded;
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(InspectionJob job) async {
    job.updatedAt = DateTime.now();
    final dir = await _reportsDir();
    final file = File(p.join(dir.path, '${job.id}.json'));
    // Önce geçici dosyaya yazıp sonra taşı: yazma yarıda kalırsa eski kayıt bozulmaz.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(job.toJson()), flush: true);
    await tmp.rename(file.path);
    if (!jobs.contains(job)) jobs.insert(0, job);
    jobs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  Future<InspectionJob> createJob(String title, {InspectionJob? copyProfileFrom}) async {
    final job = InspectionJob(id: _uuid.v4(), title: title.trim());
    if (copyProfileFrom != null) {
      job.profile = copyProfileFrom.profile.copy();
    }
    await save(job);
    return job;
  }

  Future<void> deleteJob(InspectionJob job) async {
    final dir = await _reportsDir();
    final file = File(p.join(dir.path, '${job.id}.json'));
    if (await file.exists()) await file.delete();
    final media = Directory(p.join(dir.path, job.id));
    if (await media.exists()) await media.delete(recursive: true);
    jobs.remove(job);
    notifyListeners();
  }

  /// Yeni pano raporu: rapor numarası seriden, saatler bir önceki panonun bitişinden devam eder.
  PanelReport newPanel(InspectionJob job) {
    final profile = job.profile;
    final prev = job.reports.isNotEmpty ? job.reports.last : null;
    final start = prev?.end ?? _roundToMinute(DateTime.now());
    final end = start.add(Duration(minutes: profile.minutesPerPanel));
    final report = PanelReport(
      id: _uuid.v4(),
      reportNo: '${profile.reportNoPrefix}${profile.nextReportNo}',
      start: start,
      end: end,
      reportDate: DateTime(start.year, start.month, start.day),
      nextDate: DateTime(start.year + 1, start.month, start.day),
      method: prev != null ? List.of(prev.method) : null,
      ikKa: prev?.ikKa ?? '',
      spdType: prev?.spdType ?? '',
      spdKa: prev?.spdKa ?? '',
    );
    profile.nextReportNo++;
    job.reports.add(report);
    return report;
  }

  static DateTime _roundToMinute(DateTime d) => DateTime(d.year, d.month, d.day, d.hour, d.minute);

  /// Seçilen fotoğrafı görev klasörüne kopyalar ve göreli yolunu döner.
  Future<String> importMedia(InspectionJob job, String sourcePath) async {
    final dir = Directory(p.join((await _reportsDir()).path, job.id, 'media'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final name = '${_uuid.v4()}$ext';
    await File(sourcePath).copy(p.join(dir.path, name));
    return p.join('reports', job.id, 'media', name);
  }

  /// Logo görevden bağımsız klasörde tutulur; profili kopyalanan görevler aynı logoyu kullanır
  /// ve bir görev silinince logo kaybolmaz.
  Future<String> importLogo(String sourcePath) async {
    final dir = Directory(p.join((await _reportsDir()).path, 'logos'));
    if (!await dir.exists()) await dir.create(recursive: true);
    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final name = '${_uuid.v4()}$ext';
    await File(sourcePath).copy(p.join(dir.path, name));
    return p.join('reports', 'logos', name);
  }

  Future<File?> resolveMedia(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return null;
    final f = File(p.join((await _docsDir()).path, relativePath));
    return await f.exists() ? f : null;
  }

  Future<void> deleteMedia(String? relativePath) async {
    final f = await resolveMedia(relativePath);
    if (f != null) await f.delete();
  }
}
