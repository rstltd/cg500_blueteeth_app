/// Design System - Unified export for all design-related utilities.
///
/// This file provides a single import point for the entire design system,
/// including tokens, colors, text styles, and responsive utilities.
///
/// Usage:
/// ```dart
/// import 'package:cg500_blueteeth_app/design/design_system.dart';
///
/// Container(
///   padding: DesignTokens.paddingM,
///   decoration: BoxDecoration(
///     color: AppColors.cardColor(context),
///     borderRadius: DesignTokens.borderRadiusM,
///   ),
///   child: Text(
///     'Hello',
///     style: AppTextStyles.bodyMedium(context),
///   ),
/// )
/// ```
library;

// Core design tokens
export 'design_tokens.dart';

// Text styles
export 'app_text_styles.dart';

// Button and input styles
export 'app_button_styles.dart';

// Re-export existing utilities
export '../utils/app_colors.dart';
export '../utils/responsive_utils.dart';
export '../widgets/responsive_layout.dart';
