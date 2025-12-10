import 'package:flutter/material.dart';
import '../../design/design_system.dart';
import '../../models/command/command.dart';
import '../../l10n/app_strings.dart';

/// A tab bar widget for filtering commands by category.
///
/// Displays tabs for each command category plus an "All" option.
class CommandCategoryTabs extends StatelessWidget {
  /// The currently selected category. Null means "All".
  final CommandCategory? selectedCategory;

  /// Callback when a category is selected.
  final ValueChanged<CommandCategory?> onCategorySelected;

  /// Command counts for each category (optional).
  final Map<CommandCategory, int>? categoryCounts;

  /// Total command count for "All" tab (optional).
  final int? totalCount;

  /// Whether to show command counts.
  final bool showCounts;

  /// Whether to use compact mode.
  final bool compact;

  const CommandCategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categoryCounts,
    this.totalCount,
    this.showCounts = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
      child: Row(
        children: [
          // "All" tab
          _CategoryTab(
            label: AppStrings.all,
            icon: Icons.apps,
            isSelected: selectedCategory == null,
            count: showCounts ? totalCount : null,
            onTap: () => onCategorySelected(null),
            compact: compact,
          ),
          SizedBox(width: DesignTokens.spacingS),

          // Category tabs
          ...CommandCategory.values.map((category) {
            return Padding(
              padding: EdgeInsets.only(right: DesignTokens.spacingS),
              child: _CategoryTab(
                label: category.displayName,
                icon: _getCategoryIcon(category),
                isSelected: selectedCategory == category,
                count: showCounts ? (categoryCounts?[category]) : null,
                onTap: () => onCategorySelected(category),
                color: _getCategoryColor(context, category),
                compact: compact,
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(CommandCategory category) {
    switch (category) {
      case CommandCategory.query:
        return Icons.info_outline;
      case CommandCategory.config:
        return Icons.settings;
      case CommandCategory.control:
        return Icons.sync;
      case CommandCategory.debug:
        return Icons.bug_report;
    }
  }

  Color _getCategoryColor(BuildContext context, CommandCategory category) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (category) {
      case CommandCategory.query:
        return colorScheme.primary;
      case CommandCategory.config:
        return colorScheme.tertiary;
      case CommandCategory.control:
        return Colors.orange;
      case CommandCategory.debug:
        return colorScheme.secondary;
    }
  }
}

class _CategoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final int? count;
  final VoidCallback onTap;
  final Color? color;
  final bool compact;

  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.count,
    this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignTokens.borderRadiusFull,
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          curve: DesignTokens.curveStandard,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? DesignTokens.spacingSM : DesignTokens.spacingM,
            vertical: compact ? DesignTokens.spacingS : DesignTokens.spacingSM,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: DesignTokens.borderRadiusFull,
            border: Border.all(
              color: isSelected
                  ? effectiveColor.withValues(alpha: 0.5)
                  : colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: compact ? DesignTokens.iconXS : DesignTokens.iconS,
                color: isSelected
                    ? effectiveColor
                    : colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? DesignTokens.fontS : DesignTokens.fontM,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? effectiveColor
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              if (count != null) ...[
                SizedBox(width: DesignTokens.spacingXS),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingXS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? effectiveColor.withValues(alpha: 0.2)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: DesignTokens.borderRadiusFull,
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: DesignTokens.fontCaption,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? effectiveColor
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A vertical category selector for sidebar layouts.
class CommandCategorySidebar extends StatelessWidget {
  /// The currently selected category. Null means "All".
  final CommandCategory? selectedCategory;

  /// Callback when a category is selected.
  final ValueChanged<CommandCategory?> onCategorySelected;

  /// Command counts for each category (optional).
  final Map<CommandCategory, int>? categoryCounts;

  /// Total command count for "All" option (optional).
  final int? totalCount;

  const CommandCategorySidebar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.categoryCounts,
    this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // "All" option
        _SidebarItem(
          label: AppStrings.allCommands,
          icon: Icons.apps,
          isSelected: selectedCategory == null,
          count: totalCount,
          onTap: () => onCategorySelected(null),
        ),
        SizedBox(height: DesignTokens.spacingXS),

        Divider(
          height: DesignTokens.spacingM,
          color: colorScheme.outlineVariant,
        ),

        // Category options
        ...CommandCategory.values.map((category) {
          return Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.spacingXS),
            child: _SidebarItem(
              label: category.displayName,
              icon: _getCategoryIcon(category),
              description: category.description,
              isSelected: selectedCategory == category,
              count: categoryCounts?[category],
              onTap: () => onCategorySelected(category),
              color: _getCategoryColor(context, category),
            ),
          );
        }),
      ],
    );
  }

  IconData _getCategoryIcon(CommandCategory category) {
    switch (category) {
      case CommandCategory.query:
        return Icons.info_outline;
      case CommandCategory.config:
        return Icons.settings;
      case CommandCategory.control:
        return Icons.sync;
      case CommandCategory.debug:
        return Icons.bug_report;
    }
  }

  Color _getCategoryColor(BuildContext context, CommandCategory category) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (category) {
      case CommandCategory.query:
        return colorScheme.primary;
      case CommandCategory.config:
        return colorScheme.tertiary;
      case CommandCategory.control:
        return Colors.orange;
      case CommandCategory.debug:
        return colorScheme.secondary;
    }
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? description;
  final bool isSelected;
  final int? count;
  final VoidCallback onTap;
  final Color? color;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.description,
    this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignTokens.borderRadiusM,
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          curve: DesignTokens.curveStandard,
          padding: EdgeInsets.all(DesignTokens.spacingSM),
          decoration: BoxDecoration(
            color: isSelected
                ? effectiveColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: DesignTokens.borderRadiusM,
            border: isSelected
                ? Border.all(
                    color: effectiveColor.withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? effectiveColor.withValues(alpha: 0.15)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: DesignTokens.borderRadiusS,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: DesignTokens.iconS,
                    color: isSelected
                        ? effectiveColor
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: DesignTokens.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: DesignTokens.fontM,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? effectiveColor
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (description != null)
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: DesignTokens.fontS,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (count != null) ...[
                SizedBox(width: DesignTokens.spacingS),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXS,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? effectiveColor.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: DesignTokens.borderRadiusFull,
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: DesignTokens.fontS,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? effectiveColor
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
