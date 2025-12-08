import 'package:flutter/material.dart';
import '../../design/design_system.dart';

/// A consistent section card widget used throughout the app.
///
/// Provides a styled card container with a header row containing
/// an icon and title, followed by children content.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.headerColor,
    this.elevation,
    this.padding,
    this.trailing,
  });

  /// The title text displayed in the header.
  final String title;

  /// The icon displayed in the header.
  final IconData icon;

  /// The content widgets displayed below the header.
  final List<Widget> children;

  /// Optional custom header background color.
  final Color? headerColor;

  /// Optional custom elevation for the card.
  final double? elevation;

  /// Optional custom padding for children.
  final EdgeInsets? padding;

  /// Optional trailing widget in the header.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? DesignTokens.elevationM,
      color: AppColors.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Padding(
            padding: padding ?? DesignTokens.paddingM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: DesignTokens.paddingM,
      decoration: BoxDecoration(
        color: headerColor ?? AppColors.backgroundGradientStart(context),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(DesignTokens.radiusM),
          topRight: Radius.circular(DesignTokens.radiusM),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary(context)),
          SizedBox(width: DesignTokens.spacingM),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium(context),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A minimal section card without header, just styled content.
class AppContentCard extends StatelessWidget {
  const AppContentCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.borderColor,
    this.borderWidth,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? borderColor;
  final double? borderWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? DesignTokens.elevationS,
      color: AppColors.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: DesignTokens.borderRadiusM,
        side: borderColor != null
            ? BorderSide(
                color: borderColor!,
                width: borderWidth ?? DesignTokens.dividerThickness,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: padding ?? DesignTokens.paddingM,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: DesignTokens.borderRadiusM,
        child: card,
      );
    }

    return card;
  }
}

/// A status indicator card with colored border.
class AppStatusCard extends StatelessWidget {
  const AppStatusCard({
    super.key,
    required this.child,
    required this.statusColor,
    this.icon,
    this.padding,
  });

  final Widget child;
  final Color statusColor;
  final IconData? icon;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: DesignTokens.durationNormal,
      padding: padding ?? DesignTokens.paddingM,
      decoration: BoxDecoration(
        color: AppColors.cardColor(context),
        borderRadius: DesignTokens.borderRadiusM,
        border: Border.all(
          color: statusColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: DesignTokens.paddingS,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: DesignTokens.borderRadiusS,
              ),
              child: Icon(
                icon,
                color: statusColor,
                size: DesignTokens.iconM,
              ),
            ),
            SizedBox(width: DesignTokens.spacingM),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}
