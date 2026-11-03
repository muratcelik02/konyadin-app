import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'report_storage.dart';

ReportStorage createStorage(String? rootDir) => _FileReportStorage(rootDir);

/// <belgeler>/reports/<id>.json ve <belgeler>/reports/<id>/media/...
class _FileReportStorage implements ReportStorage {
  String? _root;
  _FileReportStorage(this._root);

  Future<String> _rootDir() async => _root ??= (await getApplicationDocumentsDirectory()).path;

  Future<File> _file(String relativePath) async => File(p.joinAll([await _rootDir(), ...relativePath.split('/')]));

  @override
  Future<List<String>> readJobs() async {
    final dir = Directory(p.join(await _rootDir(), 'reports'));
    if (!await dir.exists()) return [];
    final result = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          result.add(await entity.readAsString());
        } catch (e) {
          debugPrint('Görev okunamadı: ${entity.path}: $e');
        }
      }
    }
    return result;
  }

  @override
  Future<void> writeJob(String id, String json) async {
    final file = await _file('reports/$id.json');
    await file.parent.create(recursive: true);
    // Önce geçici dosyaya yazıp sonra taşı: yazma yarıda kalırsa eski kayıt bozulmaz.
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(json, flush: true);
    await tmp.rename(file.path);
  }

  @override
  Future<void> deleteJob(String id) async {
    final file = await _file('reports/$id.json');
    if (await file.exists()) await file.delete();
    final media = Directory(p.join(await _rootDir(), 'reports', id));
    if (await media.exists()) await media.delete(recursive: true);
  }

  @override
  Future<void> writeMedia(String path, Uint8List bytes) async {
    final file = await _file(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List?> readMedia(String path) async {
    final file = await _file(path);
    return await file.exists() ? file.readAsBytes() : null;
  }

  @override
  Future<void> deleteMedia(String path) async {
    final file = await _file(path);
    if (await file.exists()) await file.delete();
  }
}
