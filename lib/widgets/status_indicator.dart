import 'package:flutter/material.dart';

class StatusIndicator extends StatelessWidget {
  final bool? isOnline;
  final VoidCallback onRefresh;

  const StatusIndicator({
    super.key,
    required this.isOnline,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    if (isOnline == null) {
      color = Colors.amber;
      text = 'Kontrol ediliyor...';
      icon = Icons.sync;
    } else if (isOnline == true) {
      color = const Color(0xFF10B981);
      text = 'Sunucu Bağlı';
      icon = Icons.check_circle_outline;
    } else {
      color = const Color(0xFFEF4444);
      text = 'Sunucu Erişilemez';
      icon = Icons.cloud_off_outlined;
    }

    return InkWell(
      onTap: onRefresh,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
