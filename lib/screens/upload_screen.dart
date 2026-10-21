import 'package:flutter/material.dart';
import '../controllers/collection_controller.dart';
import 'success_screen.dart';

class UploadScreen extends StatefulWidget {
  final CollectionController controller;

  const UploadScreen({super.key, required this.controller});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz yükleme sürecini tetikle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startUpload();
    });
  }

  Future<void> _startUpload() async {
    final success = await widget.controller.uploadAndComplete();
    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(controller: widget.controller),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isUploading = widget.controller.isUploading;
        final progress = widget.controller.uploadProgress;
        final statusMessage = widget.controller.uploadStatusMessage;
        final error = widget.controller.uploadError;
        final draft = widget.controller.currentDraft;
        final totalPhotos = draft?.photos.length ?? 0;

        return PopScope(
          canPop: !isUploading,
          onPopInvoked: (didPop) {
            if (!didPop && isUploading) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Yükleme devam ederken sayfadan ayrılamazsınız.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Sunucuya Yükleniyor'),
              automaticallyImplyLeading: !isUploading && error != null,
            ),
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Durum İkonu
                      Center(
                        child: error != null
                            ? Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Color(0xFFEF4444),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E5BB0).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 64,
                                  color: Color(0xFF1E5BB0),
                                ),
                              ),
                      ),
                      const SizedBox(height: 28),

                      // Başlık
                      Text(
                        error != null ? 'Yükleme Başarısız' : 'Dosyalar Aktarılıyor',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Klasör Adı ve Toplam Bilgisi
                      if (draft != null)
                        Text(
                          'Klasör: "${draft.name}" ($totalPhotos Fotoğraf)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      const SizedBox(height: 28),

                      // İlerleme Çubuğu ve Yüzde
                      if (error == null) ...[
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E5BB0)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              statusMessage,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '%${(progress * 100).toInt()}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E5BB0),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Hata Mesajı Alanı
                      if (error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Hata Detayı',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                error,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Yeniden Dene Butonu
                        ElevatedButton.icon(
                          onPressed: _startUpload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Geri Dön ve Kontrol Et'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
