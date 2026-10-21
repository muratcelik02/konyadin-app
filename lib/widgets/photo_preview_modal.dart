import 'dart:io';
import 'package:flutter/material.dart';

class PhotoPreviewModal extends StatelessWidget {
  final String imagePath;
  final int sequenceNumber;
  final String title;

  const PhotoPreviewModal({
    super.key,
    required this.imagePath,
    required this.sequenceNumber,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 650),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlık çubuğu
                Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fotoğraf #$sequenceNumber ($title)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Fotoğraf Görüntüleyici (InteractiveViewer ile zoom/pan)
                Flexible(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'Fotoğraf yüklenemedi',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
