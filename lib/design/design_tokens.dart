import 'package:flutter/material.dart';
import '../utils/accessibility_utils.dart';

/// Design Tokens - Centralized design system constants.
///
/// This class provides a single source of truth for all design-related values
/// used throughout the application. Using these tokens ensures visual consistency
/// and makes global design changes easy to implement.
///
/// Usage:
/// ```dart
/// Container(
///   padding: EdgeInsets.all(DesignTokens.spacingM),
///   decoration: BoxDecoration(
///     borderRadius: BorderRadius.circular(DesignTokens.radiusM),
///   ),
/// )
/// ```
class DesignTokens {
  DesignTokens._(); // Prevent instantiation

  // ============================================================
  // SPACING - Use for padding, margin, and gaps
  // ============================================================

  /// Extra small spacing: 4dp
  static const double spacingXS = 4.0;

  /// Small spacing: 8dp
  static const double spacingS = 8.0;

  /// Medium spacing: 16dp (default)
  static const double spacingM = 16.0;

  /// Large spacing: 24dp
  static const double spacingL = 24.0;

  /// Extra large spacing: 32dp
  static const double spacingXL = 32.0;

  /// Double extra large spacing: 48dp
  static const double spacingXXL = 48.0;

  // ============================================================
  // BORDER RADIUS - Use for rounded corners
  // ============================================================

  /// Extra small radius: 4dp
  static const double radiusXS = 4.0;

  /// Small radius: 8dp
  static const double radiusS = 8.0;

  /// Medium radius: 12dp (default for cards)
  static const double radiusM = 12.0;

  /// Large radius: 16dp
  static const double radiusL = 16.0;

  /// Extra large radius: 20dp
  static const double radiusXL = 20.0;

  /// Full/circular radius: 999dp
  static const double radiusFull = 999.0;

  // ============================================================
  // ELEVATION / SHADOW
  // ============================================================

  /// No elevation
  static const double elevationNone = 0.0;

  /// Small elevation: 2dp
  static const double elevationS = 2.0;

  /// Medium elevation: 4dp (default for cards)
  static const double elevationM = 4.0;

  /// Large elevation: 8dp
  static const double elevationL = 8.0;

  /// Extra large elevation: 12dp
  static const double elevationXL = 12.0;

  // ============================================================
  // BLUR RADIUS (for shadows and effects)
  // ============================================================

  /// Small blur radius: 4dp
  static const double blurRadiusS = 4.0;

  /// Medium blur radius: 8dp
  static const double blurRadiusM = 8.0;

  /// Large blur radius: 12dp
  static const double blurRadiusL = 12.0;

  /// Extra large blur radius: 16dp
  static const double blurRadiusXL = 16.0;

  // ============================================================
  // ANIMATION DURATIONS
  // ============================================================

  /// Instant/no animation: 0ms
  static const Duration durationInstant = Duration.zero;

  /// Fast animation: 150ms (micro-interactions)
  static const Duration durationFast = Duration(milliseconds: 150);

  /// Normal animation: 300ms (default transitions)
  static const Duration durationNormal = Duration(milliseconds: 300);

  /// Slow animation: 500ms (emphasized transitions)
  static const Duration durationSlow = Duration(milliseconds: 500);

  /// Extra slow animation: 800ms (complex animations)
  static const Duration durationXSlow = Duration(milliseconds: 800);

  // ============================================================
  // ANIMATION CURVES
  // ============================================================

  /// Standard curve for most animations
  static const Curve curveStandard = Curves.easeInOut;

  /// Curve for entering elements
  static const Curve curveEnter = Curves.easeOut;

  /// Curve for exiting elements
  static const Curve curveExit = Curves.easeIn;

  /// Curve for emphasized/bouncy animations
  static const Curve curveEmphasized = Curves.elasticOut;

  // ============================================================
  // ICON SIZES
  // ============================================================

  /// Extra small icon: 16dp
  static const double iconXS = 16.0;

  /// Small icon: 20dp
  static const double iconS = 20.0;

  /// Medium icon: 24dp (default)
  static const double iconM = 24.0;

  /// Large icon: 32dp
  static const double iconL = 32.0;

  /// Extra large icon: 48dp
  static const double iconXL = 48.0;

  /// Hero icon: 64dp
  static const double iconHero = 64.0;

  // ============================================================
  // FONT SIZES (Base sizes, use with ResponsiveUtils for scaling)
  // ============================================================

  /// Caption text: 10dp
  static const double fontCaption = 10.0;

  /// Small text: 12dp
  static const double fontS = 12.0;

  /// Body text: 14dp (default)
  static const double fontM = 14.0;

  /// Large body text: 16dp
  static const double fontL = 16.0;

  /// Subtitle: 18dp
  static const double fontSubtitle = 18.0;

  /// Title: 20dp
  static const double fontTitle = 20.0;

  /// Headline: 24dp
  static const double fontHeadline = 24.0;

  /// Large headline: 32dp
  static const double fontHeadlineLarge = 32.0;

  // ============================================================
  // LINE HEIGHTS
  // ============================================================

  /// Tight line height: 1.2
  static const double lineHeightTight = 1.2;

  /// Normal line height: 1.5
  static const double lineHeightNormal = 1.5;

  /// Relaxed line height: 1.75
  static const double lineHeightRelaxed = 1.75;

  // ============================================================
  // TOUCH TARGETS
  // ============================================================

  /// Minimum touch target size (iOS HIG): 44dp
  static const double touchTargetMin = 44.0;

  /// Standard touch target size (Material): 48dp
  static const double touchTargetStandard = 48.0;

  /// Large touch target size: 56dp
  static const double touchTargetLarge = 56.0;

  // ============================================================
  // LAYOUT CONSTANTS
  // ============================================================

  /// Default app bar height
  static const double appBarHeight = 56.0;

  /// Bottom navigation bar height
  static const double bottomNavHeight = 56.0;

  /// Standard divider thickness
  static const double dividerThickness = 1.0;

  /// Thick divider
  static const double dividerThick = 2.0;

  /// Maximum content width for readability
  static const double maxContentWidth = 600.0;

  /// Maximum card width on larger screens
  static const double maxCardWidth = 480.0;

  // ============================================================
  // OPACITY VALUES
  // ============================================================

  /// Disabled state opacity
  static const double opacityDisabled = 0.38;

  /// Medium opacity (for overlays)
  static const double opacityMedium = 0.54;

  /// High opacity (for secondary elements)
  static const double opacityHigh = 0.87;

  /// Full opacity
  static const double opacityFull = 1.0;

  // ============================================================
  // HELPER METHODS
  // ============================================================

  /// Get standard border radius
  static BorderRadius get borderRadiusS => BorderRadius.circular(radiusS);
  static BorderRadius get borderRadiusM => BorderRadius.circular(radiusM);
  static BorderRadius get borderRadiusL => BorderRadius.circular(radiusL);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);

  /// Get standard edge insets
  static EdgeInsets get paddingXS => EdgeInsets.all(spacingXS);
  static EdgeInsets get paddingS => EdgeInsets.all(spacingS);
  static EdgeInsets get paddingM => EdgeInsets.all(spacingM);
  static EdgeInsets get paddingL => EdgeInsets.all(spacingL);
  static EdgeInsets get paddingXL => EdgeInsets.all(spacingXL);

  /// Get horizontal padding
  static EdgeInsets get paddingHorizontalS =>
      EdgeInsets.symmetric(horizontal: spacingS);
  static EdgeInsets get paddingHorizontalM =>
      EdgeInsets.symmetric(horizontal: spacingM);
  static EdgeInsets get paddingHorizontalL =>
      EdgeInsets.symmetric(horizontal: spacingL);

  /// Get vertical padding
  static EdgeInsets get paddingVerticalS =>
      EdgeInsets.symmetric(vertical: spacingS);
  static EdgeInsets get paddingVerticalM =>
      EdgeInsets.symmetric(vertical: spacingM);
  static EdgeInsets get paddingVerticalL =>
      EdgeInsets.symmetric(vertical: spacingL);

  /// Get standard box shadow for cards
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Get subtle box shadow
  static List<BoxShadow> subtleShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.05),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  /// Get elevated box shadow
  static List<BoxShadow> elevatedShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.4)
            : Colors.black.withValues(alpha: 0.15),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // ============================================================
  // ACCESSIBILITY-AWARE ANIMATIONS
  // ============================================================

  /// Get animation duration that respects reduced motion preference.
  static Duration getAccessibleDuration(
    BuildContext context, {
    Duration? duration,
  }) {
    return AccessibilityUtils.getAnimationDuration(
      context,
      duration ?? durationNormal,
    );
  }

  /// Get fast animation duration that respects reduced motion preference.
  static Duration getAccessibleFastDuration(BuildContext context) {
    return AccessibilityUtils.getFastDuration(context);
  }

  /// Get slow animation duration that respects reduced motion preference.
  static Duration getAccessibleSlowDuration(BuildContext context) {
    return AccessibilityUtils.getSlowDuration(context);
  }

  /// Get animation curve that respects reduced motion preference.
  static Curve getAccessibleCurve(BuildContext context, {Curve? curve}) {
    return AccessibilityUtils.getAnimationCurve(
      context,
      curve ?? curveStandard,
    );
  }
}
