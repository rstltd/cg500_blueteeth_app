import 'package:flutter/material.dart';

/// Custom painter for animated checkmark.
///
/// Draws a checkmark that animates from left to right,
/// creating a satisfying success indicator.
class CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  CheckmarkPainter({
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

    final path = Path();

    // Draw checkmark path
    final p1 = Offset(size.width * 0.2, size.height * 0.5);
    final p2 = Offset(size.width * 0.45, size.height * 0.7);
    final p3 = Offset(size.width * 0.8, size.height * 0.3);

    if (progress <= 0.5) {
      // First half: draw from p1 to p2
      final currentProgress = progress * 2;
      final currentPoint = Offset.lerp(p1, p2, currentProgress)!;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    } else {
      // Second half: draw from p2 to p3
      final currentProgress = (progress - 0.5) * 2;
      final currentPoint = Offset.lerp(p2, p3, currentProgress)!;
      path.moveTo(p1.dx, p1.dy);
      path.lineTo(p2.dx, p2.dy);
      path.lineTo(currentPoint.dx, currentPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
