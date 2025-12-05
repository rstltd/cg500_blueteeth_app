import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter for scanning radar animation.
///
/// Creates a radar-like visual effect with:
/// - An outer circle border
/// - A rotating scanning arc
/// - Expanding ripple effects
class ScanningRadarPainter extends CustomPainter {
  final double progress;
  final Color color;

  ScanningRadarPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle
    final outerPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, outerPaint);

    // Draw scanning arc
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final sweepAngle = math.pi / 3; // 60 degrees
    final startAngle = progress * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // Draw expanding ripples
    for (int i = 0; i < 3; i++) {
      final rippleProgress = (progress + i * 0.33) % 1.0;
      final rippleRadius = radius * rippleProgress;
      final rippleAlpha = (1.0 - rippleProgress) * 0.5;

      final ripplePaint = Paint()
        ..color = color.withValues(alpha: rippleAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
