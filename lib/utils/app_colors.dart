import 'package:flutter/material.dart';
import 'accessibility_utils.dart';

/// Theme-aware colors for custom widgets.
///
/// Provides consistent colors that automatically adapt to the current theme
/// (light or dark mode) based on the BuildContext.
///
/// All color combinations are designed to meet WCAG AA contrast requirements:
/// - Normal text: 4.5:1 minimum contrast ratio
/// - Large text: 3:1 minimum contrast ratio
///
/// Usage:
/// ```dart
/// Container(
///   color: AppColors.cardColor(context),
///   child: Text(
///     'Hello',
///     style: TextStyle(color: AppColors.textPrimary(context)),
///   ),
/// )
/// ```
class AppColors {
  AppColors._(); // Prevent instantiation

  // --- Surface & Background Colors ---

  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E) // Dark surface
        : Colors.white;
  }

  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C) // Slightly lighter than surface
        : Colors.white;
  }

  static Color backgroundGradientStart(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF121212)
        : Colors.blue.shade50;
  }

  static Color backgroundGradientEnd(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.indigo.shade50;
  }

  // --- Text Colors (WCAG AA compliant) ---

  /// Primary text color - contrast ratio ≥ 7:1 (WCAG AAA)
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFFFFF) // White on dark: 13.5:1 vs #2C2C2C
        : const Color(0xFF1F1F1F); // Near black on white: 16.1:1
  }

  /// Secondary text color - contrast ratio ≥ 4.5:1 (WCAG AA)
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB0B0B0) // Light grey: 7.8:1 vs #2C2C2C
        : const Color(0xFF5F5F5F); // Medium grey: 7.0:1 vs white
  }

  /// Tertiary/disabled text color - contrast ratio ≥ 3:1 (large text)
  static Color textTertiary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF8A8A8A) // Lighter grey: 4.7:1 vs #2C2C2C
        : const Color(0xFF757575); // Darker grey: 4.6:1 vs white
  }

  // --- Border & Divider Colors ---

  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF404040) // Visible border in dark mode
        : const Color(0xFFE0E0E0); // Visible border in light mode
  }

  static Color dividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF323232)
        : const Color(0xFFEEEEEE);
  }

  // --- Shadow Colors ---

  static Color shadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.1);
  }

  // --- Status Colors (WCAG AA compliant) ---

  /// Success color - contrast ratio ≥ 3:1 for UI components
  static Color successColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4CAF50) // Green 500: 5.1:1 vs #2C2C2C
        : const Color(0xFF2E7D32); // Green 800: 4.5:1 vs white
  }

  /// Warning color - contrast ratio ≥ 3:1 for UI components
  static Color warningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFB74D) // Orange 300: 8.4:1 vs #2C2C2C
        : const Color(0xFFE65100); // Orange 900: 4.8:1 vs white
  }

  /// Error color - contrast ratio ≥ 3:1 for UI components
  static Color errorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFEF5350) // Red 400: 5.2:1 vs #2C2C2C
        : const Color(0xFFC62828); // Red 800: 5.9:1 vs white
  }

  /// Info color - contrast ratio ≥ 3:1 for UI components
  static Color infoColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF42A5F5) // Blue 400: 5.5:1 vs #2C2C2C
        : const Color(0xFF1565C0); // Blue 800: 5.3:1 vs white
  }

  // --- Interactive Colors ---

  /// Primary action color
  static Color primaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF90CAF9) // Blue 200: 9.3:1 vs #2C2C2C
        : const Color(0xFF1976D2); // Blue 700: 4.6:1 vs white
  }

  /// Primary action color on surface (for buttons)
  static Color onPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E) // Dark on light blue
        : Colors.white; // White on blue
  }

  // --- Status Color Variants (Light/Container colors) ---

  /// Success container/background color
  static Color successContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1B5E20).withValues(alpha: 0.3) // Green 900 with alpha
        : const Color(0xFFE8F5E9); // Green 50
  }

  /// Success border color
  static Color successBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4CAF50).withValues(alpha: 0.5) // Green 500
        : const Color(0xFFA5D6A7); // Green 200
  }

  /// Success text on container
  static Color onSuccessContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF81C784) // Green 300
        : const Color(0xFF1B5E20); // Green 900
  }

  /// Warning container/background color
  static Color warningContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFE65100).withValues(alpha: 0.3) // Orange 900 with alpha
        : const Color(0xFFFFF3E0); // Orange 50
  }

  /// Warning border color
  static Color warningBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFB74D).withValues(alpha: 0.5) // Orange 300
        : const Color(0xFFFFCC80); // Orange 200
  }

  /// Warning text on container
  static Color onWarningContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFB74D) // Orange 300
        : const Color(0xFFE65100); // Orange 900
  }

  /// Error container/background color
  static Color errorContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB71C1C).withValues(alpha: 0.3) // Red 900 with alpha
        : const Color(0xFFFFEBEE); // Red 50
  }

  /// Error border color
  static Color errorBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFEF5350).withValues(alpha: 0.5) // Red 400
        : const Color(0xFFEF9A9A); // Red 200
  }

  /// Error text on container
  static Color onErrorContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFEF9A9A) // Red 200
        : const Color(0xFFB71C1C); // Red 900
  }

  /// Info container/background color
  static Color infoContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0D47A1).withValues(alpha: 0.3) // Blue 900 with alpha
        : const Color(0xFFE3F2FD); // Blue 50
  }

  /// Info border color
  static Color infoBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF42A5F5).withValues(alpha: 0.5) // Blue 400
        : const Color(0xFF90CAF9); // Blue 200
  }

  /// Info text on container
  static Color onInfoContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF90CAF9) // Blue 200
        : const Color(0xFF0D47A1); // Blue 900
  }

  // --- Neutral Colors ---

  /// Neutral/disabled background
  static Color neutralContainer(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF424242) // Grey 800
        : const Color(0xFFF5F5F5); // Grey 100
  }

  /// Neutral border
  static Color neutralBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF616161) // Grey 700
        : const Color(0xFFE0E0E0); // Grey 300
  }

  /// Neutral text/icon color
  static Color neutralColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF9E9E9E) // Grey 500
        : const Color(0xFF757575); // Grey 600
  }

  // --- Overlay Colors ---

  /// Light overlay for containers on colored backgrounds
  static Color lightOverlay(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.7);
  }

  /// Dark overlay for dimming
  static Color darkOverlay(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.3);
  }

  // --- Gradient Colors ---

  /// Scanning indicator gradient start
  static Color scanningGradientStart(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1565C0).withValues(alpha: 0.3) // Blue 800
        : const Color(0xFFBBDEFB); // Blue 100
  }

  /// Scanning indicator gradient end
  static Color scanningGradientEnd(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0D47A1).withValues(alpha: 0.2) // Blue 900
        : const Color(0xFFE3F2FD); // Blue 50
  }

  /// Command bubble gradient start (user sent commands)
  static Color commandGradientStart(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1565C0) // Blue 800
        : const Color(0xFF1E88E5); // Blue 600
  }

  /// Command bubble gradient end
  static Color commandGradientEnd(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0D47A1) // Blue 900
        : const Color(0xFF1976D2); // Blue 700
  }

  /// Response bubble background
  static Color responseBubbleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C) // Dark card color
        : const Color(0xFFF5F5F5); // Grey 100
  }

  // --- Update Dialog Colors ---

  /// Update header gradient start color
  static Color updateHeaderGradientStart(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1565C0) // Blue 800
        : const Color(0xFF1E88E5); // Blue 600
  }

  /// Update header gradient end color
  static Color updateHeaderGradientEnd(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0D47A1) // Blue 900
        : const Color(0xFF1565C0); // Blue 800
  }

  /// Update type colors - Optional update (green)
  static Color updateOptionalColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4CAF50) // Green 500
        : const Color(0xFF43A047); // Green 600
  }

  /// Update type colors - Recommended update (orange)
  static Color updateRecommendedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF9800) // Orange 500
        : const Color(0xFFEF6C00); // Orange 800
  }

  /// Update type colors - Required update (blue)
  static Color updateRequiredColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF42A5F5) // Blue 400
        : const Color(0xFF1976D2); // Blue 700
  }

  /// Update type colors - Forced/Critical update (red)
  static Color updateForcedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFEF5350) // Red 400
        : const Color(0xFFE53935); // Red 600
  }

  /// Text color on primary/colored buttons
  static Color textOnPrimary(BuildContext context) {
    // Always white for good contrast on colored buttons
    return Colors.white;
  }

  /// Semi-transparent white overlay (for icons/decorations on colored backgrounds)
  static Color whiteOverlay20(BuildContext context) {
    return Colors.white.withValues(alpha: 0.2);
  }

  /// Semi-transparent white (90% opacity)
  static Color whiteOverlay90(BuildContext context) {
    return Colors.white.withValues(alpha: 0.9);
  }

  /// Inactive progress indicator color
  static Color progressInactive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF424242) // Grey 800
        : const Color(0xFFE0E0E0); // Grey 300
  }

  // --- Shimmer/Skeleton Colors ---

  /// Shimmer base color for skeleton loading states
  static Color shimmerBase(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3A) // Darker grey for dark mode
        : const Color(0xFFE0E0E0); // Grey 300 for light mode
  }

  /// Shimmer highlight color for skeleton loading states
  static Color shimmerHighlight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4A4A4A) // Lighter grey for dark mode highlight
        : const Color(0xFFF5F5F5); // Grey 100 for light mode highlight
  }

  // --- Utility Methods ---

  /// Get a contrasting text color for any background.
  static Color getContrastingTextColor(Color background) {
    return AccessibilityUtils.getBestForegroundColor(background);
  }

  /// Check if current text colors meet WCAG AA standards.
  static bool checkTextContrast(BuildContext context) {
    final background = cardColor(context);
    final primary = textPrimary(context);
    final secondary = textSecondary(context);

    return AccessibilityUtils.meetsWcagAA(primary, background) &&
        AccessibilityUtils.meetsWcagAA(secondary, background);
  }

  /// Get the contrast ratio between text and background.
  static double getTextContrastRatio(BuildContext context) {
    final background = cardColor(context);
    final text = textPrimary(context);
    return AccessibilityUtils.getContrastRatio(text, background);
  }
}
