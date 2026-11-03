import 'dart:typed_data';
import 'report_storage_io.dart' if (dart.library.js_interop) 'report_storage_web.dart' as impl;

/// Görev JSON'ları ve fotoğraflar için kalıcı depo.
/// Telefonda belge klasörüne dosya olarak, tarayıcıda (web önizleme) tarayıcı deposuna yazar.
/// Medya yolları her zaman "/" ayraçlı ve göreli: reports/<görev>/media/<ad>.jpg
abstract class ReportStorage {
  /// rootDir yalnızca testler için (telefonda belge klasörü kullanılır; web'de yok sayılır).
  factory ReportStorage({String? rootDir}) => impl.createStorage(rootDir);

  Future<List<String>> readJobs();
  Future<void> writeJob(String id, String json);

  /// Görev kaydını ve görevin medya klasörünü siler.
  Future<void> deleteJob(String id);

  Future<void> writeMedia(String path, Uint8List bytes);
  Future<Uint8List?> readMedia(String path);
  Future<void> deleteMedia(String path);
}
