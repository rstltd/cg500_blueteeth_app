import 'package:flutter/material.dart';
import '../design/design_tokens.dart';

/// Accessibility utilities for the app.
///
/// Provides methods to check and respect user accessibility preferences,
/// including reduced motion settings, high contrast mode, and screen reader support.
class AccessibilityUtils {
  AccessibilityUtils._(); // Prevent instantiation

  /// Check if the user prefers reduced motion.
  ///
  /// Returns true if the user has enabled "Reduce motion" in their
  /// device accessibility settings.
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get animation duration respecting reduced motion preference.
  ///
  /// Returns [Duration.zero] if user prefers reduced motion,
  /// otherwise returns the provided [duration].
  static Duration getAnimationDuration(
    BuildContext context,
    Duration duration,
  ) {
    return prefersReducedMotion(context) ? Duration.zero : duration;
  }

  /// Get animation curve respecting reduced motion preference.
  ///
  /// Returns [Curves.linear] for instant transitions if user prefers
  /// reduced motion, otherwise returns the provided [curve].
  static Curve getAnimationCurve(BuildContext context, Curve curve) {
    return prefersReducedMotion(context) ? Curves.linear : curve;
  }

  /// Check if bold text is enabled.
  ///
  /// Returns true if the user has enabled "Bold Text" in their
  /// device accessibility settings.
  static bool usesBoldText(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Check if high contrast mode is enabled.
  ///
  /// Returns true if the user has enabled "Increase Contrast" in their
  /// device accessibility settings.
  static bool usesHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Get the current text scale factor.
  ///
  /// Returns the text scaling factor set by the user in their
  /// device accessibility settings.
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// Check if inverted colors are enabled.
  ///
  /// Returns true if the user has enabled color inversion.
  static bool usesInvertedColors(BuildContext context) {
    return MediaQuery.of(context).invertColors;
  }

  /// Get the platform brightness (light/dark mode).
  static Brightness getPlatformBrightness(BuildContext context) {
    return MediaQuery.of(context).platformBrightness;
  }

  // --- Accessible Animation Helpers ---

  /// Get standard animation duration respecting user preferences.
  static Duration getStandardDuration(BuildContext context) {
    return getAnimationDuration(context, DesignTokens.durationNormal);
  }

  /// Get fast animation duration respecting user preferences.
  static Duration getFastDuration(BuildContext context) {
    return getAnimationDuration(context, DesignTokens.durationFast);
  }

  /// Get slow animation duration respecting user preferences.
  static Duration getSlowDuration(BuildContext context) {
    return getAnimationDuration(context, DesignTokens.durationSlow);
  }

  // --- WCAG Contrast Helpers ---

  /// Calculate the luminance of a color (0.0 = dark, 1.0 = light).
  static double getLuminance(Color color) {
    return color.computeLuminance();
  }

  /// Calculate the contrast ratio between two colors.
  ///
  /// Returns a value between 1 (no contrast) and 21 (maximum contrast).
  /// WCAG AA requires 4.5:1 for normal text and 3:1 for large text.
  /// WCAG AAA requires 7:1 for normal text and 4.5:1 for large text.
  static double getContrastRatio(Color foreground, Color background) {
    final foregroundLuminance = foreground.computeLuminance();
    final backgroundLuminance = background.computeLuminance();

    final lighter = foregroundLuminance > backgroundLuminance
        ? foregroundLuminance
        : backgroundLuminance;
    final darker = foregroundLuminance > backgroundLuminance
        ? backgroundLuminance
        : foregroundLuminance;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if the contrast ratio meets WCAG AA for normal text (4.5:1).
  static bool meetsWcagAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 4.5;
  }

  /// Check if the contrast ratio meets WCAG AA for large text (3:1).
  static bool meetsWcagAALargeText(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 3.0;
  }

  /// Check if the contrast ratio meets WCAG AAA for normal text (7:1).
  static bool meetsWcagAAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 7.0;
  }

  /// Check if the contrast ratio meets WCAG AAA for large text (4.5:1).
  static bool meetsWcagAAALargeText(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 4.5;
  }

  /// Get the best foreground color (black or white) for the given background.
  static Color getBestForegroundColor(Color background) {
    return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  // --- Touch Target Helpers ---

  /// Get the minimum touch target size for accessibility.
  ///
  /// Returns 48dp as per WCAG 2.1 Success Criterion 2.5.5.
  static double getMinTouchTargetSize() {
    return 48.0;
  }

  /// Check if a size meets the minimum touch target requirements.
  static bool meetsMinTouchTarget(double size) {
    return size >= 48.0;
  }
}

/// A widget that wraps animated widgets with reduced motion support.
///
/// This widget will automatically disable or simplify animations
/// when the user has enabled "Reduce motion" in their accessibility settings.
class AccessibleAnimatedWidget extends StatelessWidget {
  const AccessibleAnimatedWidget({
    super.key,
    required this.child,
    required this.reducedChild,
  });

  /// The widget to display when animations are allowed.
  final Widget child;

  /// The widget to display when reduced motion is preferred.
  final Widget reducedChild;

  @override
  Widget build(BuildContext context) {
    if (AccessibilityUtils.prefersReducedMotion(context)) {
      return reducedChild;
    }
    return child;
  }
}

/// A mixin that provides accessible animation support.
mixin AccessibleAnimationMixin<T extends StatefulWidget>
    on SingleTickerProviderStateMixin<T> {
  late AnimationController _animationController;
  bool _reducedMotion = false;

  /// Initialize the animation controller with accessibility support.
  void initAccessibleAnimation({
    required Duration duration,
    Duration? reverseDuration,
  }) {
    _animationController = AnimationController(
      duration: duration,
      reverseDuration: reverseDuration,
      vsync: this,
    );
  }

  /// Update reduced motion preference.
  void updateReducedMotion(BuildContext context) {
    final newReducedMotion = AccessibilityUtils.prefersReducedMotion(context);
    if (_reducedMotion != newReducedMotion) {
      _reducedMotion = newReducedMotion;
      if (_reducedMotion) {
        _animationController.duration = Duration.zero;
        _animationController.reverseDuration = Duration.zero;
      }
    }
  }

  /// Get the animation controller.
  AnimationController get animationController => _animationController;

  /// Check if reduced motion is enabled.
  bool get isReducedMotion => _reducedMotion;

  /// Dispose the animation controller.
  void disposeAccessibleAnimation() {
    _animationController.dispose();
  }
}
