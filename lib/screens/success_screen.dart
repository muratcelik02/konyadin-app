import 'package:flutter/material.dart';
import '../controllers/collection_controller.dart';
import 'home_screen.dart';

class SuccessScreen extends StatelessWidget {
  final CollectionController controller;

  const SuccessScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    // Controller geçmişinden son tamamlanan öğeyi alalım
    final latest = controller.previousCollections.isNotEmpty
        ? controller.previousCollections.first
        : null;

    final folderName = latest?['name'] ?? 'Klasör';
    final photoCount = latest?['photo_count'] ?? 0;
    final noteFormat = latest?['note_format'] ?? 'md';
    final noteFilename = latest?['note_filename'] ?? 'notes.$noteFormat';
    final dirName = latest?['dir_name'] ?? '';

    return PopScope(
      canPop: false,
      onPopInvoked: (_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HomeScreen(controller: controller)),
          (route) => false,
        );
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Başarı İkonu
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Başlık
                const Text(
                  'Klasör Başarıyla Oluşturuldu!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fotoğraflarınız, notlarınız ve metaverileriniz sunucuda güvenle saklandı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // Detay Kartı
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        context,
                        icon: Icons.folder,
                        label: 'Klasör Adı',
                        value: folderName,
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        context,
                        icon: Icons.photo_library,
                        label: 'Yüklenen Fotoğraf',
                        value: '$photoCount Adet',
                      ),
                      const Divider(height: 20),
                      _buildInfoRow(
                        context,
                        icon: Icons.description,
                        label: 'Not Dosyası',
                        value: '$noteFilename (${noteFormat.toUpperCase()})',
                      ),
                      if (dirName.isNotEmpty) ...[
                        const Divider(height: 20),
                        _buildInfoRow(
                          context,
                          icon: Icons.storage,
                          label: 'Sunucu Dizin Adı',
                          value: dirName,
                        ),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                // Ana Ekrana Dön Butonu
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => HomeScreen(controller: controller),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Ana Ekrana Dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1E5BB0)),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
