import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'design_tokens.dart';

/// Button size variants for responsive button sizing.
enum ButtonSize {
  /// Small button - compact actions, icon buttons
  small,

  /// Medium button - default size for most actions
  medium,

  /// Large button - primary CTAs, prominent actions
  large,
}

/// Button size configuration with padding and text style.
class _ButtonSizeConfig {
  final EdgeInsets padding;
  final double minHeight;
  final double iconSize;
  final double fontSize;
  final FontWeight fontWeight;
  final BorderRadius borderRadius;

  const _ButtonSizeConfig({
    required this.padding,
    required this.minHeight,
    required this.iconSize,
    required this.fontSize,
    required this.fontWeight,
    required this.borderRadius,
  });

  /// Get configuration for button size
  static _ButtonSizeConfig forSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return _ButtonSizeConfig(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingSM,
            vertical: DesignTokens.spacingXS,
          ),
          minHeight: 32,
          iconSize: DesignTokens.iconXS,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          borderRadius: DesignTokens.borderRadiusS,
        );
      case ButtonSize.medium:
        return _ButtonSizeConfig(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingL,
            vertical: DesignTokens.spacingSM,
          ),
          minHeight: 40,
          iconSize: DesignTokens.iconS,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          borderRadius: DesignTokens.borderRadiusM,
        );
      case ButtonSize.large:
        return _ButtonSizeConfig(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingXL,
            vertical: DesignTokens.spacingM,
          ),
          minHeight: 52,
          iconSize: DesignTokens.iconM,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          borderRadius: DesignTokens.borderRadiusL,
        );
    }
  }
}

/// Button style variants for consistent button appearance.
///
/// Provides factory methods for creating button styles with proper
/// disabled, focused, and pressed states.
///
/// Usage:
/// ```dart
/// ElevatedButton(
///   style: AppButtonStyles.primary(context, size: ButtonSize.large),
///   onPressed: () {},
///   child: Text('Submit'),
/// )
/// ```
class AppButtonStyles {
  AppButtonStyles._();

  // --- Primary Buttons (filled) ---

  /// Primary button style - main call-to-action
  ///
  /// [size] - Button size variant (default: medium)
  static ButtonStyle primary(
    BuildContext context, {
    ButtonSize size = ButtonSize.medium,
  }) {
    final config = _ButtonSizeConfig.forSize(size);
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryColor(context),
      foregroundColor: AppColors.onPrimaryColor(context),
      disabledBackgroundColor: AppColors.neutralContainer(context),
      disabledForegroundColor: AppColors.textTertiary(context),
      padding: config.padding,
      minimumSize: Size(0, config.minHeight),
      textStyle: TextStyle(
        fontSize: config.fontSize,
        fontWeight: config.fontWeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: config.borderRadius,
      ),
      elevation: 0,
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.white.withValues(alpha: 0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return Colors.white.withValues(alpha: 0.05);
        }
        if (states.contains(WidgetState.focused)) {
          return Colors.white.withValues(alpha: 0.1);
        }
        return null;
      }),
    );
  }

  /// @deprecated Use [primary] instead
  static ButtonStyle primaryButton(BuildContext context) =>
      primary(context, size: ButtonSize.medium);

  /// Success button style - confirmations, positive actions
  ///
  /// [size] - Button size variant (default: medium)
  static ButtonStyle success(
    BuildContext context, {
    ButtonSize size = ButtonSize.medium,
  }) {
    final config = _ButtonSizeConfig.forSize(size);
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.successColor(context),
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.neutralContainer(context),
      disabledForegroundColor: AppColors.textTertiary(context),
      padding: config.padding,
      minimumSize: Size(0, config.minHeight),
      textStyle: TextStyle(
        fontSize: config.fontSize,
        fontWeight: config.fontWeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: config.borderRadius,
      ),
      elevation: 0,
    );
  }

  /// @deprecated Use [success] instead
  static ButtonStyle successButton(BuildContext context) =>
      success(context, size: ButtonSize.medium);

  /// Error/Danger button style - destructive actions
  ///
  /// [size] - Button size variant (default: medium)
  static ButtonStyle danger(
    BuildContext context, {
    ButtonSize size = ButtonSize.medium,
  }) {
    final config = _ButtonSizeConfig.forSize(size);
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.errorColor(context),
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.neutralContainer(context),
      disabledForegroundColor: AppColors.textTertiary(context),
      padding: config.padding,
      minimumSize: Size(0, config.minHeight),
      textStyle: TextStyle(
        fontSize: config.fontSize,
        fontWeight: config.fontWeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: config.borderRadius,
      ),
      elevation: 0,
    );
  }

  /// @deprecated Use [danger] instead
  static ButtonStyle dangerButton(BuildContext context) =>
      danger(context, size: ButtonSize.medium);

  /// Info button style - informational actions
  ///
  /// [size] - Button size variant (default: medium)
  static ButtonStyle info(
    BuildContext context, {
    ButtonSize size = ButtonSize.medium,
  }) {
    final config = _ButtonSizeConfig.forSize(size);
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.infoColor(context),
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.neutralContainer(context),
      disabledForegroundColor: AppColors.textTertiary(context),
      padding: config.padding,
      minimumSize: Size(0, config.minHeight),
      textStyle: TextStyle(
        fontSize: config.fontSize,
        fontWeight: config.fontWeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: config.borderRadius,
      ),
      elevation: 0,
    );
  }

  /// Warning button style - caution actions
  ///
  /// [size] - Button size variant (default: medium)
  static ButtonStyle warning(
    BuildContext context, {
    ButtonSize size = ButtonSize.medium,
  }) {
    final config = _ButtonSizeConfig.forSize(size);
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.warningColor(context),
      foregroundColor: Colors.black87,
      disabledBackgroundColor: AppColors.neutralContainer(context),
      disabledForegroundColor: AppColors.textTertiary(context),
      padding: config.padding,
      minimumSize: Size(0, config.minHeight),
      textStyle: TextStyle(
        fontSize: config.fontSize,
        fontWeight: config.fontWeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: config.borderRadius,
      ),
      elevation: 0,
    );
  }

  // --- Secondary Buttons (outlined) ---

  /// Secondary button style - alternative actions
  ///
  /// [size] - Button size variant (default: medium)
  static ButtonStyle secondary(
    BuildContext context, {
    ButtonSize size = ButtonSize.medium,
  }) {
    final config = _ButtonSizeConfig.forSize(size);
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryColor(context),
      disabledForegroundColor: AppColors.textTertiary(context),
      padding: config.padding,
      minimumSize: Size(0, config.minHeight),
      textStyle: TextStyle(
        fontSize: config.fontSize,
        fontWeight: config.fontWeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: config.borderRadius,
      ),
      side: BorderSide(
        color: AppColors.primaryColor(context),
        width: 1.5,
      ),
    ).copyWith(
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: AppColors.neutralBorder(context),
            width: 1.5,
          );
        }
        if (states.contains(WidgetState.focused)) {
          return BorderSide(
            color: AppColors.primaryColor(context),
            width: 2,
          );
        }
        return BorderSide(
          color: AppColors.primaryColor(context),
          width: 1.5,
        );
      }),
    );
  }

  /// @deprecated Use [secondary] instead
  static ButtonStyle secondaryButton(BuildContext context) =>
      secondary(context, size: ButtonSize.medium);

  /// Outlined danger button style - destructive secondary actions
  ///
  /// [size] - Button size variant (default: medium)
  static ButtonStyle secondaryDanger(
    BuildContext context, {
    ButtonSize size = ButtonSize.medium,
  }) {
    final config = _ButtonSizeConfig.forSize(size);
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.errorColor(context),
      disabledForegroundColor: AppColors.textTertiary(context),
      padding: config.padding,
      minimumSize: Size(0, config.minHeight),
      textStyle: TextStyle(
        fontSize: config.fontSize,
        fontWeight: config.fontWeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: config.borderRadius,
      ),
      side: BorderSide(
        color: AppColors.errorColor(context),
        width: 1.5,
      ),
    ).copyWith(
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(
            color: AppColors.neutralBorder(context),
            width: 1.5,
          );
        }
        return BorderSide(
          color: AppColors.errorColor(context),
          width: 1.5,
        );
      }),
    );
  }

  // --- Text Buttons ---

  /// Text button style - tertiary actions
  ///
  /// [size] - Button size variant (default: medium)
  static ButtonStyle text(
    BuildContext context, {
    ButtonSize size = ButtonSize.medium,
  }) {
    final config = _ButtonSizeConfig.forSize(size);
    return TextButton.styleFrom(
      foregroundColor: AppColors.primaryColor(context),
      disabledForegroundColor: AppColors.textTertiary(context),
      padding: config.padding,
      minimumSize: Size(0, config.minHeight),
      textStyle: TextStyle(
        fontSize: config.fontSize,
        fontWeight: config.fontWeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: config.borderRadius,
      ),
    );
  }

  /// @deprecated Use [text] instead
  static ButtonStyle textButton(BuildContext context) =>
      text(context, size: ButtonSize.medium);

  /// Text danger button style - destructive tertiary actions
  ///
  /// [size] - Button size variant (default: medium)
  static ButtonStyle textDanger(
    BuildContext context, {
    ButtonSize size = ButtonSize.medium,
  }) {
    final config = _ButtonSizeConfig.forSize(size);
    return TextButton.styleFrom(
      foregroundColor: AppColors.errorColor(context),
      disabledForegroundColor: AppColors.textTertiary(context),
      padding: config.padding,
      minimumSize: Size(0, config.minHeight),
      textStyle: TextStyle(
        fontSize: config.fontSize,
        fontWeight: config.fontWeight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: config.borderRadius,
      ),
    );
  }

  // --- Icon Buttons ---

  /// Icon button style with proper states
  ///
  /// [size] - Button size variant (default: medium)
  static ButtonStyle icon(
    BuildContext context, {
    ButtonSize size = ButtonSize.medium,
  }) {
    final config = _ButtonSizeConfig.forSize(size);
    return IconButton.styleFrom(
      foregroundColor: AppColors.textSecondary(context),
      disabledForegroundColor: AppColors.textTertiary(context),
      minimumSize: Size(config.minHeight, config.minHeight),
      iconSize: config.iconSize,
      padding: EdgeInsets.all(config.padding.vertical),
      shape: RoundedRectangleBorder(
        borderRadius: config.borderRadius,
      ),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return AppColors.neutralContainer(context);
        }
        if (states.contains(WidgetState.hovered)) {
          return AppColors.neutralContainer(context).withValues(alpha: 0.5);
        }
        if (states.contains(WidgetState.focused)) {
          return AppColors.neutralContainer(context);
        }
        return Colors.transparent;
      }),
    );
  }

  /// @deprecated Use [icon] instead
  static ButtonStyle iconButton(BuildContext context) =>
      icon(context, size: ButtonSize.medium);

  // --- Utility Methods ---

  /// Get icon size for button size variant
  static double getIconSize(ButtonSize size) {
    return _ButtonSizeConfig.forSize(size).iconSize;
  }

  /// Get minimum button height for size variant
  static double getMinHeight(ButtonSize size) {
    return _ButtonSizeConfig.forSize(size).minHeight;
  }
}

/// Input decoration factory for consistent text field styling.
class AppInputStyles {
  AppInputStyles._();

  /// Standard text field decoration
  static InputDecoration standard(
    BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabled: enabled,
      filled: true,
      fillColor: enabled
          ? AppColors.surfaceColor(context)
          : AppColors.neutralContainer(context),
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingSM,
      ),
      border: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusM,
        borderSide: BorderSide(
          color: AppColors.borderColor(context),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusM,
        borderSide: BorderSide(
          color: AppColors.borderColor(context),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusM,
        borderSide: BorderSide(
          color: AppColors.primaryColor(context),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusM,
        borderSide: BorderSide(
          color: AppColors.errorColor(context),
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusM,
        borderSide: BorderSide(
          color: AppColors.errorColor(context),
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusM,
        borderSide: BorderSide(
          color: AppColors.neutralBorder(context),
          width: 1,
        ),
      ),
      labelStyle: TextStyle(
        color: enabled
            ? AppColors.textSecondary(context)
            : AppColors.textTertiary(context),
      ),
      hintStyle: TextStyle(
        color: AppColors.textTertiary(context),
      ),
    );
  }

  /// Search field decoration
  static InputDecoration search(
    BuildContext context, {
    String? hintText,
    VoidCallback? onClear,
  }) {
    return InputDecoration(
      hintText: hintText ?? 'Search...',
      prefixIcon: Icon(
        Icons.search,
        color: AppColors.textSecondary(context),
      ),
      suffixIcon: onClear != null
          ? IconButton(
              icon: Icon(
                Icons.clear,
                color: AppColors.textSecondary(context),
              ),
              onPressed: onClear,
            )
          : null,
      filled: true,
      fillColor: AppColors.neutralContainer(context),
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingSM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        borderSide: BorderSide(
          color: AppColors.primaryColor(context),
          width: 2,
        ),
      ),
    );
  }

  /// Command input decoration (for BLE command interface)
  static InputDecoration command(
    BuildContext context, {
    String? hintText,
    bool enabled = true,
  }) {
    return InputDecoration(
      hintText: hintText ?? 'Enter command...',
      enabled: enabled,
      filled: true,
      fillColor: enabled
          ? AppColors.surfaceColor(context)
          : AppColors.neutralContainer(context),
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingSM,
      ),
      border: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusM,
        borderSide: BorderSide(
          color: enabled
              ? AppColors.infoBorder(context)
              : AppColors.neutralBorder(context),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusM,
        borderSide: BorderSide(
          color: AppColors.borderColor(context),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusM,
        borderSide: BorderSide(
          color: AppColors.infoColor(context),
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: DesignTokens.borderRadiusM,
        borderSide: BorderSide(
          color: AppColors.neutralBorder(context),
          width: 1,
        ),
      ),
      hintStyle: TextStyle(
        color: AppColors.textTertiary(context),
      ),
    );
  }
}
