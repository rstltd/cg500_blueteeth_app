import 'package:flutter/material.dart';

/// Custom painter for animated error mark (X).
///
/// Draws an X mark that animates by drawing each line sequentially,
/// creating a clear error indicator.
class ErrorMarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  ErrorMarkPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    if (progress <= 0.5) {
      // First line of X
      final currentProgress = progress * 2;
      final start = Offset(center.dx - radius, center.dy - radius);
      final end = Offset(center.dx + radius, center.dy + radius);
      final currentEnd = Offset.lerp(start, end, currentProgress)!;

      canvas.drawLine(start, currentEnd, paint);
    } else {
      // Both lines of X
      final currentProgress = (progress - 0.5) * 2;

      // First line (complete)
      canvas.drawLine(
        Offset(center.dx - radius, center.dy - radius),
        Offset(center.dx + radius, center.dy + radius),
        paint,
      );

      // Second line (animated)
      final start2 = Offset(center.dx - radius, center.dy + radius);
      final end2 = Offset(center.dx + radius, center.dy - radius);
      final currentEnd2 = Offset.lerp(start2, end2, currentProgress)!;

      canvas.drawLine(start2, currentEnd2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
