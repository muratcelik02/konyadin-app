import 'dart:io';
import 'package:flutter/material.dart';
import '../models/photo_item.dart';
import 'photo_preview_modal.dart';

class PhotoCard extends StatelessWidget {
  final PhotoItem photo;
  final VoidCallback onDelete;
  final VoidCallback onRetake;

  const PhotoCard({
    super.key,
    required this.photo,
    required this.onDelete,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Küçük Önizleme Resmi
          Positioned.fill(
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => PhotoPreviewModal(
                    imagePath: photo.localPath,
                    sequenceNumber: photo.sequenceNumber,
                    title: photo.originalName,
                  ),
                );
              },
              child: Image.file(
                File(photo.localPath),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),
          ),

          // Üst Sıra Rozeti
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#${photo.sequenceNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // Alt Eylemler Çubuğu
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.65),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Büyüt
                  IconButton(
                    icon: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                    tooltip: 'Büyük Önizleme',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => PhotoPreviewModal(
                          imagePath: photo.localPath,
                          sequenceNumber: photo.sequenceNumber,
                          title: photo.originalName,
                        ),
                      );
                    },
                  ),
                  // Yeniden Çek
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.amberAccent, size: 20),
                    tooltip: 'Yeniden Çek',
                    onPressed: onRetake,
                  ),
                  // Sil
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    tooltip: 'Fotoğrafı Sil',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
