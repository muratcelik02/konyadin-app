import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'report_storage.dart';

ReportStorage createStorage(String? rootDir) => _PrefsReportStorage();

/// Web önizleme: veriler tarayıcı deposunda (localStorage) tutulur.
/// Tarayıcı deposu birkaç MB ile sınırlıdır; yalnızca deneme amaçlıdır, birkaç fotoğraftan sonra dolabilir.
class _PrefsReportStorage implements ReportStorage {
  static const _jobPrefix = 'report_job:';
  static const _mediaPrefix = 'report_media:';

  @override
  Future<List<String>> readJobs() async {
    final prefs = await SharedPreferences.getInstance();
    return [
      for (final k in prefs.getKeys())
        if (k.startsWith(_jobPrefix)) prefs.getString(k) ?? '',
    ].where((s) => s.isNotEmpty).toList();
  }

  @override
  Future<void> writeJob(String id, String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_jobPrefix$id', json);
  }

  @override
  Future<void> deleteJob(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_jobPrefix$id');
    final mediaKeys = prefs.getKeys().where((k) => k.startsWith('${_mediaPrefix}reports/$id/')).toList();
    for (final k in mediaKeys) {
      await prefs.remove(k);
    }
  }

  @override
  Future<void> writeMedia(String path, Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_mediaPrefix$path', base64Encode(bytes));
  }

  @override
  Future<Uint8List?> readMedia(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString('$_mediaPrefix$path');
    return s == null ? null : base64Decode(s);
  }

  @override
  Future<void> deleteMedia(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_mediaPrefix$path');
  }
}
