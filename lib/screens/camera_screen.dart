import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/collection_controller.dart';
import '../widgets/photo_card.dart';
import 'notes_screen.dart';

class CameraScreen extends StatefulWidget {
  final CollectionController controller;

  const CameraScreen({super.key, required this.controller});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isCapturing = false;

  Future<void> _capturePhoto({int? replaceIndex}) async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100, // Orijinal kalite korunur
      );

      if (photo != null) {
        final file = File(photo.path);
        final fileSize = await file.length();
        final fileName = photo.name;

        if (replaceIndex != null) {
          widget.controller.replacePhoto(
            index: replaceIndex,
            newLocalPath: photo.path,
            newOriginalName: fileName,
            newFileSize: fileSize,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Fotoğraf #${replaceIndex + 1} yenisiyle değiştirildi.'),
                backgroundColor: const Color(0xFF10B981),
              ),
            );
          }
        } else {
          widget.controller.addPhoto(
            localPath: photo.path,
            originalName: fileName,
            fileSize: fileSize,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kameraya erişilemedi: $e. Lütfen kamera izinlerini kontrol edin.'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (photo != null) {
        final file = File(photo.path);
        final fileSize = await file.length();
        widget.controller.addPhoto(
          localPath: photo.path,
          originalName: photo.name,
          fileSize: fileSize,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Galeriye erişilemedi: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fotoğrafı Sil'),
        content: Text('Fotoğraf #${index + 1} silinsin mi? Sıradaki fotoğrafların numaraları otomatik güncellenecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () {
              widget.controller.removePhoto(index);
              Navigator.of(ctx).pop();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _onFinishPhotos() {
    if (widget.controller.photoCount == 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Fotoğraf Gerekli'),
          content: const Text(
            'Klasörleme işlemine devam edebilmek için en az bir fotoğraf çekmelisiniz.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _capturePhoto();
              },
              child: const Text('Kamerayı Aç'),
            ),
          ],
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotesScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final photos = widget.controller.currentDraft?.photos ?? [];
        final count = photos.length;
        final folderName = widget.controller.currentDraft?.name ?? 'Klasör';

        return Scaffold(
          appBar: AppBar(
            title: Text(folderName),
            actions: [
              IconButton(
                icon: const Icon(Icons.photo_library_outlined),
                tooltip: 'Galeriden Seç',
                onPressed: _pickFromGallery,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Durum ve sayaç çubuğu
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        count == 0
                            ? 'Henüz fotoğraf çekilmedi'
                            : '$count fotoğraf çekildi',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _isCapturing ? null : () => _capturePhoto(),
                        icon: const Icon(Icons.add_a_photo, size: 18),
                        label: const Text('Yeni Çek'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Fotoğraflar Listesi / Grid
                Expanded(
                  child: count == 0
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E5BB0).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 64,
                                    color: Color(0xFF1E5BB0),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Fotoğraf Çekmeye Başlayın',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Bu klasöre eklemek istediğiniz fotoğrafları çekiniz. Çekilen fotoğraflar sırasıyla klasörlenecektir.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => _capturePhoto(),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Kamerayı Aç ve Çek'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: count,
                          itemBuilder: (context, index) {
                            final photo = photos[index];
                            return PhotoCard(
                              photo: photo,
                              onDelete: () => _confirmDelete(index),
                              onRetake: () => _capturePhoto(replaceIndex: index),
                            );
                          },
                        ),
                ),

                // Alt Aksiyon Çubuğu: Klasörlemeyi Bitir Butonu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _onFinishPhotos,
                    icon: const Icon(Icons.description_outlined),
                    label: Text(
                      count == 0
                          ? 'Klasörlemeyi Bitir (Fotoğraf Gereklidir)'
                          : 'Klasörlemeyi Bitir ($count Fotoğraf)',
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: count > 0
              ? FloatingActionButton.extended(
                  onPressed: _isCapturing ? null : () => _capturePhoto(),
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Fotoğraf Ekle'),
                )
              : null,
        );
      },
    );
  }
}
