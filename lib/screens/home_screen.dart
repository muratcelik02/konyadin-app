import 'package:flutter/material.dart';
import '../controllers/collection_controller.dart';
import '../widgets/status_indicator.dart';
import 'folder_name_screen.dart';
import 'camera_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final CollectionController controller;

  const HomeScreen({super.key, required this.controller});

  void _onStart(BuildContext context) {
    // Eğer yarım kalan taslak varsa doğrudan kamera ekranına veya isim ekranına yönlendirebiliriz
    if (controller.currentDraft != null && controller.currentDraft!.photos.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Devam Eden İşlem Bulundu'),
          content: Text(
            '"${controller.currentDraft!.name}" başlıklı klasörünüzde ${controller.currentDraft!.photos.length} fotoğraf bulunmaktadır. Bu klasöre devam etmek ister misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.discardCurrentDraft();
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => FolderNameScreen(controller: controller)),
                );
              },
              child: const Text('Yeni Klasör Başlat'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CameraScreen(controller: controller)),
                );
              },
              child: const Text('Devam Et'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FolderNameScreen(controller: controller)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isOnline = controller.isServerOnline;
        final history = controller.previousCollections;
        final hasDraft = controller.currentDraft != null && controller.currentDraft!.photos.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Klasörüm'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: StatusIndicator(
                  isOnline: isOnline,
                  onRefresh: () => controller.checkServerStatus(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Sunucu Ayarları',
                onPressed: () async {
                  final changed = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  if (changed == true) {
                    controller.checkServerStatus();
                    controller.loadHistory();
                  }
                },
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await controller.checkServerStatus();
                await controller.loadHistory();
              },
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  const SizedBox(height: 10),

                  // Karşılama ve Tanıtım Kartı
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E5BB0), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E5BB0).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.folder_copy,
                          size: 44,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Klasörüm',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Fotoğraflarını ve notlarını güvenle klasörle.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Büyük ve Belirgin "Başla" Butonu
                        ElevatedButton.icon(
                          onPressed: () => _onStart(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E5BB0),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.add_photo_alternate_rounded),
                          label: const Text(
                            'Başla',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Kurtarılabilir Taslak Uyarısı
                  if (hasDraft) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.restore, color: Colors.amber.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Yarım Kalan Klasör: ${controller.currentDraft!.name}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${controller.currentDraft!.photos.length} fotoğraf bekliyor',
                                  style: TextStyle(color: Colors.amber.shade800, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => CameraScreen(controller: controller)),
                              );
                            },
                            child: const Text('Devam Et'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Önceki Klasörler Başlığı
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Önceki Klasörler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (controller.isLoadingHistory)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Klasör Geçmişi Listesi
                  if (history.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_done_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Henüz sunucuda kayıtlı bir klasör yok.',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '"Başla" butonuna basarak ilk klasörünüzü oluşturun.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ...history.map((item) {
                      final name = item['name'] ?? 'İsimsiz Klasör';
                      final count = item['photo_count'] ?? 0;
                      final date = item['created_at'] != null
                          ? item['created_at'].toString().split('T').first
                          : '';
                      final status = item['status'] ?? 'completed';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Theme.of(context).dividerColor.withOpacity(0.15),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1E5BB0).withOpacity(0.1),
                            child: const Icon(
                              Icons.folder,
                              color: Color(0xFF1E5BB0),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$date • $count fotoğraf • Durum: $status',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 20),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
