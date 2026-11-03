import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'report_models.dart';
import 'storage/report_storage.dart';

/// Görevleri çevrimdışı saklar (telefonda belge klasörü, web önizlemede tarayıcı deposu).
/// Fotoğraf yolları göreli tutulur; iOS'ta uygulama klasörünün tam yolu güncellemelerde değişebilir.
class ReportStore extends ChangeNotifier {
  final _uuid = const Uuid();
  final ReportStorage _storage;
  List<InspectionJob> jobs = [];
  bool isLoading = false;

  /// rootDir yalnızca testler için; uygulamada telefonun belge klasörü kullanılır.
  ReportStore({String? rootDir}) : _storage = ReportStorage(rootDir: rootDir);

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    final loaded = <InspectionJob>[];
    try {
      for (final json in await _storage.readJobs()) {
        try {
          loaded.add(InspectionJob.fromJson(jsonDecode(json) as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Görev okunamadı: $e');
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
    await _storage.writeJob(job.id, jsonEncode(job.toJson()));
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
    await _storage.deleteJob(job.id);
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

  Future<String> _import(XFile source, String folder) async {
    final ext = p.extension(source.name).isEmpty ? '.jpg' : p.extension(source.name).toLowerCase();
    final path = '$folder/${_uuid.v4()}$ext';
    await _storage.writeMedia(path, await source.readAsBytes());
    return path;
  }

  /// Seçilen fotoğrafı görevin medya klasörüne kopyalar ve göreli yolunu döner.
  Future<String> importMedia(InspectionJob job, XFile source) => _import(source, 'reports/${job.id}/media');

  /// Logo görevden bağımsız klasörde tutulur; profili kopyalanan görevler aynı logoyu kullanır
  /// ve bir görev silinince logo kaybolmaz.
  Future<String> importLogo(XFile source) => _import(source, 'reports/logos');

  Future<Uint8List?> readMedia(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return null;
    return _storage.readMedia(relativePath);
  }

  Future<void> deleteMedia(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return;
    await _storage.deleteMedia(relativePath);
  }
}
