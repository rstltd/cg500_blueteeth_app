import 'package:flutter/material.dart';
import '../../design/design_system.dart';

/// A consistent empty state widget used throughout the app.
///
/// Displays an icon, title, optional message, and optional action button
/// when there's no content to show.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.compact = false,
  });

  /// The icon to display.
  final IconData icon;

  /// The main title text.
  final String title;

  /// Optional descriptive message.
  final String? message;

  /// Optional action button label.
  final String? actionLabel;

  /// Optional callback when action button is pressed.
  final VoidCallback? onAction;

  /// Optional custom icon color.
  final Color? iconColor;

  /// Whether to use compact layout (less padding).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? DesignTokens.iconXL : DesignTokens.iconHero;
    final spacing = compact ? DesignTokens.spacingS : DesignTokens.spacingM;

    return Center(
      child: Padding(
        padding: compact ? DesignTokens.paddingM : DesignTokens.paddingXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.textSecondary(context),
            ),
            SizedBox(height: spacing),
            Text(
              title,
              style: compact
                  ? AppTextStyles.titleSmall(context)
                  : AppTextStyles.titleMedium(context),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              SizedBox(height: DesignTokens.spacingS),
              Text(
                message!,
                style: AppTextStyles.bodyMedium(context).copyWith(
                  color: AppColors.textSecondary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: DesignTokens.spacingL),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A consistent error state widget.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.compact = false,
  });

  /// The error message to display.
  final String message;

  /// Optional custom title (defaults to "Error").
  final String? title;

  /// Optional callback for retry action.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String retryLabel;

  /// Whether to use compact layout.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline,
      iconColor: AppColors.errorColor(context),
      title: title ?? 'Error',
      message: message,
      actionLabel: onRetry != null ? retryLabel : null,
      onAction: onRetry,
      compact: compact,
    );
  }
}

/// A no data found state widget.
class AppNoDataState extends StatelessWidget {
  const AppNoDataState({
    super.key,
    this.title = 'No Data',
    this.message,
    this.onRefresh,
    this.compact = false,
  });

  final String title;
  final String? message;
  final VoidCallback? onRefresh;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.inbox_outlined,
      title: title,
      message: message ?? 'No items to display',
      actionLabel: onRefresh != null ? 'Refresh' : null,
      onAction: onRefresh,
      compact: compact,
    );
  }
}

/// A search empty state widget.
class AppSearchEmptyState extends StatelessWidget {
  const AppSearchEmptyState({
    super.key,
    this.searchTerm,
    this.onClearSearch,
    this.compact = false,
  });

  final String? searchTerm;
  final VoidCallback? onClearSearch;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.search_off,
      title: 'No Results Found',
      message: searchTerm != null
          ? 'No results found for "$searchTerm"'
          : 'Try adjusting your search criteria',
      actionLabel: onClearSearch != null ? 'Clear Search' : null,
      onAction: onClearSearch,
      compact: compact,
    );
  }
}
