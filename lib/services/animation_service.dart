import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/painters/scanning_radar_painter.dart';
import '../utils/painters/checkmark_painter.dart';
import '../utils/painters/error_mark_painter.dart';

// Re-export painters for backward compatibility
export '../utils/painters/scanning_radar_painter.dart' show ScanningRadarPainter;
export '../utils/painters/checkmark_painter.dart' show CheckmarkPainter;
export '../utils/painters/error_mark_painter.dart' show ErrorMarkPainter;

/// Animation service for managing various animation effects throughout the app
class AnimationService {
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration scanningDuration = Duration(milliseconds: 1500);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceInCurve = Curves.bounceIn;
  static const Curve bounceOutCurve = Curves.bounceOut;
  static const Curve elasticInCurve = Curves.elasticIn;
  static const Curve elasticOutCurve = Curves.elasticOut;

  /// Create a fade transition animation
  static Widget createFadeTransition({
    required AnimationController controller,
    required Widget child,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
  }) {
    final animation = Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));

    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Create a slide transition animation
  static Widget createSlideTransition({
    required AnimationController controller,
    required Widget child,
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
    Curve curve = defaultCurve,
  }) {
    final animation = Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));

    return SlideTransition(
      position: animation,
      child: child,
    );
  }

  /// Create a scale transition animation
  static Widget createScaleTransition({
    required AnimationController controller,
    required Widget child,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
  }) {
    final animation = Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));

    return ScaleTransition(
      scale: animation,
      child: child,
    );
  }

  /// Create a rotation transition animation
  static Widget createRotationTransition({
    required AnimationController controller,
    required Widget child,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = defaultCurve,
  }) {
    final animation = Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));

    return RotationTransition(
      turns: animation,
      child: child,
    );
  }

  /// Create a size transition animation
  static Widget createSizeTransition({
    required AnimationController controller,
    required Widget child,
    Axis axis = Axis.vertical,
    Curve curve = defaultCurve,
  }) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );

    return SizeTransition(
      sizeFactor: animation,
      axis: axis,
      child: child,
    );
  }

  /// Create a custom page transition
  static PageRouteBuilder createPageTransition({
    required Widget page,
    PageTransitionType type = PageTransitionType.slideFromRight,
    Duration duration = defaultDuration,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildPageTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
          type: type,
        );
      },
    );
  }

  /// Build specific page transition based on type
  static Widget _buildPageTransition({
    required Animation<double> animation,
    required Animation<double> secondaryAnimation,
    required Widget child,
    required PageTransitionType type,
  }) {
    switch (type) {
      case PageTransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );

      case PageTransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );

      case PageTransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );

      case PageTransitionType.slideFromTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );

      case PageTransitionType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case PageTransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          )),
          child: child,
        );

      case PageTransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );
    }
  }

  /// Create scanning radar animation
  static Widget createScanningRadar({
    required AnimationController controller,
    Color? color,
    double size = 100.0,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: ScanningRadarPainter(
            progress: controller.value,
            color: color ?? Colors.blue.shade500,
          ),
        );
      },
    );
  }

  /// Create pulse animation for connection status
  static Widget createPulseAnimation({
    required AnimationController controller,
    required Widget child,
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final scale = minScale + (maxScale - minScale) * 
                     (0.5 + 0.5 * math.sin(controller.value * 2 * math.pi));
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }

  /// Create connection status indicator animation
  static Widget createConnectionStatusAnimation({
    required AnimationController controller,
    required bool isConnected,
    required Widget child,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!isConnected) {
          return child;
        }

        // Create a breathing effect for connected devices
        final scale = 1.0 + 0.03 * math.sin(controller.value * 2 * math.pi);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
    );
  }

  /// Create success animation (checkmark)
  static Widget createSuccessAnimation({
    required AnimationController controller,
    Color? color,
    double size = 24.0,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: CheckmarkPainter(
            progress: controller.value,
            color: color ?? Colors.green,
          ),
        );
      },
    );
  }

  /// Create error animation (X mark)
  static Widget createErrorAnimation({
    required AnimationController controller,
    Color? color,
    double size = 24.0,
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(size, size),
          painter: ErrorMarkPainter(
            progress: controller.value,
            color: color ?? Colors.red,
          ),
        );
      },
    );
  }
}

/// Page transition types
enum PageTransitionType {
  slideFromRight,
  slideFromLeft,
  slideFromBottom,
  slideFromTop,
  fade,
  scale,
  rotation,
}