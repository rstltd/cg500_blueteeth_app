import 'package:flutter/material.dart';

/// Theme-aware colors for custom widgets.
///
/// Provides consistent colors that automatically adapt to the current theme
/// (light or dark mode) based on the BuildContext.
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
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E1E1E)
        : Colors.white;
  }

  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2C)
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

  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.grey.shade800;
  }

  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade400
        : Colors.grey.shade600;
  }

  static Color borderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;
  }

  static Color shadowColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.1);
  }

  // Status colors that work in both themes
  static Color successColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade600;
  }

  static Color warningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.orange.shade400
        : Colors.orange.shade600;
  }

  static Color errorColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.red.shade400
        : Colors.red.shade600;
  }

  static Color infoColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue.shade400
        : Colors.blue.shade600;
  }
}
