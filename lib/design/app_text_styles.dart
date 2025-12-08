import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_utils.dart';
import 'design_tokens.dart';

/// App Text Styles - Centralized text style definitions.
///
/// Provides consistent, responsive text styles that automatically adapt to:
/// - Device type (mobile, tablet, desktop)
/// - Theme mode (light, dark)
/// - System text scale factor
///
/// Usage:
/// ```dart
/// Text(
///   'Hello World',
///   style: AppTextStyles.headlineLarge(context),
/// )
/// ```
class AppTextStyles {
  AppTextStyles._(); // Prevent instantiation

  // ============================================================
  // HEADLINE STYLES - For page titles and major sections
  // ============================================================

  /// Large headline: 32dp base, bold
  static TextStyle headlineLarge(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontHeadlineLarge,
      ),
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightTight,
    );
  }

  /// Medium headline: 24dp base, bold
  static TextStyle headlineMedium(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontHeadline,
      ),
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightTight,
    );
  }

  /// Small headline: 20dp base, semi-bold
  static TextStyle headlineSmall(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontTitle,
      ),
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightTight,
    );
  }

  // ============================================================
  // TITLE STYLES - For card titles and section headers
  // ============================================================

  /// Large title: 20dp base, semi-bold
  static TextStyle titleLarge(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontTitle,
      ),
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Medium title: 18dp base, semi-bold
  static TextStyle titleMedium(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontSubtitle,
      ),
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Small title: 16dp base, medium weight
  static TextStyle titleSmall(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontL,
      ),
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  // ============================================================
  // BODY STYLES - For main content text
  // ============================================================

  /// Large body: 16dp base, normal weight
  static TextStyle bodyLarge(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontL,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Medium body: 14dp base, normal weight (default)
  static TextStyle bodyMedium(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontM,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Small body: 12dp base, normal weight
  static TextStyle bodySmall(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontS,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  // ============================================================
  // LABEL STYLES - For form labels and UI elements
  // ============================================================

  /// Large label: 14dp base, medium weight
  static TextStyle labelLarge(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontM,
      ),
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Medium label: 12dp base, medium weight
  static TextStyle labelMedium(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontS,
      ),
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Small label: 10dp base, medium weight
  static TextStyle labelSmall(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontCaption,
      ),
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  // ============================================================
  // CAPTION STYLES - For hints, timestamps, and metadata
  // ============================================================

  /// Caption: 12dp base, secondary color
  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontS,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Small caption: 10dp base, secondary color
  static TextStyle captionSmall(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontCaption,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  // ============================================================
  // BUTTON STYLES
  // ============================================================

  /// Button text: 14dp base, medium weight
  static TextStyle button(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontM,
      ),
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Small button text: 12dp base, medium weight
  static TextStyle buttonSmall(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontS,
      ),
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  // ============================================================
  // SPECIAL STYLES
  // ============================================================

  /// Monospace text for code/IDs
  static TextStyle monospace(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontS,
      ),
      fontWeight: FontWeight.normal,
      fontFamily: 'monospace',
      color: AppColors.textPrimary(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Error text
  static TextStyle error(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontS,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.errorColor(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Success text
  static TextStyle success(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontS,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.successColor(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Warning text
  static TextStyle warning(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontS,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.warningColor(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  /// Info text
  static TextStyle info(BuildContext context) {
    return TextStyle(
      fontSize: ResponsiveUtils.getResponsiveFontSize(
        context,
        DesignTokens.fontS,
      ),
      fontWeight: FontWeight.normal,
      color: AppColors.infoColor(context),
      height: DesignTokens.lineHeightNormal,
    );
  }

  // ============================================================
  // STYLE MODIFIERS
  // ============================================================

  /// Apply secondary color to any style
  static TextStyle withSecondaryColor(BuildContext context, TextStyle style) {
    return style.copyWith(color: AppColors.textSecondary(context));
  }

  /// Apply bold weight to any style
  static TextStyle withBold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.bold);
  }

  /// Apply italic to any style
  static TextStyle withItalic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  /// Apply underline to any style
  static TextStyle withUnderline(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }

  /// Apply custom color to any style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
}
