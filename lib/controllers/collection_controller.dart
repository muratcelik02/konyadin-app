import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/collection_draft.dart';
import '../models/photo_item.dart';
import '../services/api_client.dart';
import '../services/local_draft_storage.dart';

class CollectionController extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final Uuid _uuid = const Uuid();

  CollectionDraft? _currentDraft;
  bool? _isServerOnline;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatusMessage = '';
  String? _uploadError;
  List<dynamic> _previousCollections = [];
  bool _isLoadingHistory = false;

  // Getters
  CollectionDraft? get currentDraft => _currentDraft;
  bool? get isServerOnline => _isServerOnline;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String get uploadStatusMessage => _uploadStatusMessage;
  String? get uploadError => _uploadError;
  List<dynamic> get previousCollections => _previousCollections;
  bool get isLoadingHistory => _isLoadingHistory;

  int get photoCount => _currentDraft?.photos.length ?? 0;

  CollectionController() {
    init();
  }

  Future<void> init() async {
    await checkServerStatus();
    await _loadExistingDraft();
    await loadHistory();
  }

  Future<void> _loadExistingDraft() async {
    final draft = await LocalDraftStorage.loadDraft();
    if (draft != null) {
      _currentDraft = draft;
      notifyListeners();
    }
  }

  /// Sunucu bağlantı durumunu kontrol eder
  Future<void> checkServerStatus() async {
    final res = await _apiClient.checkHealth();
    _isServerOnline = res.isSuccess;
    notifyListeners();
  }

  /// Önceki klasörleri yükler
  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    final res = await _apiClient.listCollections();
    if (res.isSuccess && res.data != null) {
      _previousCollections = res.data!;
    }
    _isLoadingHistory = false;
    notifyListeners();
  }

  /// Yeni bir klasörleme işlemi başlatır
  void startNewCollection(String folderName) {
    final cleanName = folderName.trim();
    final newId = _uuid.v4();

    _currentDraft = CollectionDraft(
      id: newId,
      name: cleanName,
      photos: [],
      notes: '',
      noteFormat: 'md',
    );
    _uploadError = null;
    _uploadProgress = 0.0;
    _persistDraft();
    notifyListeners();
  }

  /// Fotoğraf ekler (Sıra numarası 1'den başlar)
  void addPhoto({
    required String localPath,
    required String originalName,
    required int fileSize,
  }) {
    if (_currentDraft == null) return;

    final nextSeq = _currentDraft!.photos.length + 1;
    final photoItem = PhotoItem(
      id: _uuid.v4(),
      localPath: localPath,
      sequenceNumber: nextSeq,
      originalName: originalName,
      fileSize: fileSize,
    );

    _currentDraft!.photos.add(photoItem);
    _persistDraft();
    notifyListeners();
  }

  /// Fotoğrafı siler ve kalanların sıra numaralarını günceller
  void removePhoto(int index) {
    if (_currentDraft == null || index < 0 || index >= _currentDraft!.photos.length) return;

    _currentDraft!.photos.removeAt(index);
    // Sıra numaralarını yeniden düzenle (1, 2, 3...)
    for (int i = 0; i < _currentDraft!.photos.length; i++) {
      _currentDraft!.photos[i].sequenceNumber = i + 1;
    }

    _persistDraft();
    notifyListeners();
  }

  /// Fotoğrafı yenisiyle değiştirir (Yeniden çekme)
  void replacePhoto({
    required int index,
    required String newLocalPath,
    required String newOriginalName,
    required int newFileSize,
  }) {
    if (_currentDraft == null || index < 0 || index >= _currentDraft!.photos.length) return;

    final existing = _currentDraft!.photos[index];
    _currentDraft!.photos[index] = PhotoItem(
      id: existing.id,
      localPath: newLocalPath,
      sequenceNumber: existing.sequenceNumber,
      originalName: newOriginalName,
      fileSize: newFileSize,
      isUploaded: false,
    );

    _persistDraft();
    notifyListeners();
  }

  /// Notları ve formatı günceller
  void updateNotes(String notes, String format) {
    if (_currentDraft == null) return;
    _currentDraft!.notes = notes;
    _currentDraft!.noteFormat = format;
    _persistDraft();
    notifyListeners();
  }

  /// Aktif taslağı temizler
  Future<void> discardCurrentDraft() async {
    _currentDraft = null;
    _uploadError = null;
    await LocalDraftStorage.clearDraft();
    notifyListeners();
  }

  void _persistDraft() {
    if (_currentDraft != null) {
      LocalDraftStorage.saveDraft(_currentDraft!);
    }
  }

  /// Sunucuya Yükleme ve Tamamlama Süreci (Idempotent ve Hata Yönetimli)
  Future<bool> uploadAndComplete() async {
    if (_currentDraft == null) return false;
    if (_currentDraft!.photos.isEmpty) {
      _uploadError = 'Klasör oluşturmak için en az bir fotoğraf gereklidir.';
      notifyListeners();
      return false;
    }

    _isUploading = true;
    _uploadError = null;
    _uploadProgress = 0.05;
    _uploadStatusMessage = 'Sunucuya bağlanılıyor...';
    notifyListeners();

    try {
      // Adım 1: Klasör taslağı oluştur veya mevcut olanı doğrula (Idempotent)
      _uploadStatusMessage = 'Sunucu klasörü hazırlanıyor...';
      notifyListeners();

      final createRes = await _apiClient.createCollection(
        id: _currentDraft!.id,
        name: _currentDraft!.name,
      );

      if (!createRes.isSuccess) {
        throw Exception(createRes.errorMessage ?? 'Klasör oluşturulamadı.');
      }

      final totalPhotos = _currentDraft!.photos.length;

      // Adım 2: Fotoğrafları sırayla yükle
      for (int i = 0; i < totalPhotos; i++) {
        final photo = _currentDraft!.photos[i];
        final photoIndex = i + 1;

        _uploadStatusMessage = 'Fotoğraf $photoIndex / $totalPhotos yükleniyor...';
        // Progress: %10 ile %80 arası fotoğraflara ayrılır
        _uploadProgress = 0.10 + ((i / totalPhotos) * 0.70);
        notifyListeners();

        // Eğer dosya yerelde mevcut değilse kontrol et
        final file = File(photo.localPath);
        if (!await file.exists()) {
          throw Exception('${photo.originalName} adlı fotoğraf cihazda bulunamadı.');
        }

        final uploadRes = await _apiClient.uploadPhoto(
          collectionId: _currentDraft!.id,
          filePath: photo.localPath,
          sequenceNumber: photo.sequenceNumber,
        );

        if (!uploadRes.isSuccess) {
          throw Exception('Fotoğraf $photoIndex yüklenemedi: ${uploadRes.errorMessage}');
        }

        photo.isUploaded = true;
        _persistDraft();
      }

      // Adım 3: Not dosyasını yükle/güncelle
      _uploadStatusMessage = 'Notlar kaydediliyor...';
      _uploadProgress = 0.85;
      notifyListeners();

      final notesRes = await _apiClient.updateNotes(
        collectionId: _currentDraft!.id,
        content: _currentDraft!.notes,
        format: _currentDraft!.noteFormat,
      );

      if (!notesRes.isSuccess) {
        throw Exception('Notlar kaydedilemedi: ${notesRes.errorMessage}');
      }

      // Adım 4: Klasörü tamamlandı olarak işaretle (metadata.json oluşturulur)
      _uploadStatusMessage = 'Klasörleme tamamlanıyor...';
      _uploadProgress = 0.95;
      notifyListeners();

      final completeRes = await _apiClient.completeCollection(
        collectionId: _currentDraft!.id,
      );

      if (!completeRes.isSuccess) {
        throw Exception('Klasör tamamlanamadı: ${completeRes.errorMessage}');
      }

      _uploadProgress = 1.0;
      _uploadStatusMessage = 'Tamamlandı!';
      _isUploading = false;
      notifyListeners();

      // Başarılı olduğu için yerel taslağı temizle
      await LocalDraftStorage.clearDraft();
      await loadHistory();
      return true;
    } catch (e) {
      _isUploading = false;
      _uploadError = e.toString().replaceFirst('Exception: ', '');
      _uploadStatusMessage = 'Yükleme başarısız oldu.';
      notifyListeners();
      return false;
    }
  }
}
