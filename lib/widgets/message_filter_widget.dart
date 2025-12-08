import 'package:flutter/material.dart';
import '../design/design_system.dart';

/// Filter options for messages in the command interface.
enum MessageFilter {
  all('All'),
  commands('Commands'),
  responses('Responses'),
  errors('Errors');

  const MessageFilter(this.label);
  final String label;
}

/// A widget that displays filter chips for message filtering.
///
/// Allows users to filter messages by type: All, Commands, Responses, or Errors.
class MessageFilterWidget extends StatelessWidget {
  const MessageFilterWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.messageCounts,
    this.compact = false,
  });

  /// The currently selected filter.
  final MessageFilter selectedFilter;

  /// Callback when filter selection changes.
  final ValueChanged<MessageFilter> onFilterChanged;

  /// Count of messages for each filter type.
  /// Keys should match MessageFilter enum values.
  final Map<MessageFilter, int> messageCounts;

  /// Whether to use compact layout (for mobile).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? DesignTokens.spacingS : DesignTokens.spacingM,
        vertical: DesignTokens.spacingXS,
      ),
      child: Row(
        children: MessageFilter.values.map((filter) {
          return Padding(
            padding: EdgeInsets.only(right: DesignTokens.spacingS),
            child: _FilterChip(
              filter: filter,
              isSelected: selectedFilter == filter,
              count: messageCounts[filter] ?? 0,
              onTap: () => onFilterChanged(filter),
              compact: compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filter,
    required this.isSelected,
    required this.count,
    required this.onTap,
    required this.compact,
  });

  final MessageFilter filter;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chipColor = _getChipColor(context, filter, isSelected);
    final textColor = _getTextColor(context, filter, isSelected);
    final borderColor = _getBorderColor(context, filter, isSelected);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: DesignTokens.borderRadiusFull,
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? DesignTokens.spacingSM : DesignTokens.spacingM,
            vertical: compact ? DesignTokens.spacingXS : DesignTokens.spacingS,
          ),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: DesignTokens.borderRadiusFull,
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact) ...[
                Icon(
                  _getFilterIcon(filter),
                  size: DesignTokens.iconXS,
                  color: textColor,
                ),
                SizedBox(width: DesignTokens.spacingXS),
              ],
              Text(
                filter.label,
                style: AppTextStyles.labelMedium(context).copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (count > 0) ...[
                SizedBox(width: DesignTokens.spacingXS),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingXS,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.neutralContainer(context),
                    borderRadius: DesignTokens.borderRadiusFull,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: AppTextStyles.captionSmall(context).copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
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

  IconData _getFilterIcon(MessageFilter filter) {
    switch (filter) {
      case MessageFilter.all:
        return Icons.all_inbox;
      case MessageFilter.commands:
        return Icons.send;
      case MessageFilter.responses:
        return Icons.reply;
      case MessageFilter.errors:
        return Icons.error_outline;
    }
  }

  Color _getChipColor(BuildContext context, MessageFilter filter, bool selected) {
    if (!selected) {
      return AppColors.neutralContainer(context);
    }

    switch (filter) {
      case MessageFilter.all:
        return AppColors.primaryColor(context);
      case MessageFilter.commands:
        return AppColors.infoColor(context);
      case MessageFilter.responses:
        return AppColors.successColor(context);
      case MessageFilter.errors:
        return AppColors.errorColor(context);
    }
  }

  Color _getTextColor(BuildContext context, MessageFilter filter, bool selected) {
    if (!selected) {
      return AppColors.textSecondary(context);
    }
    // All selected states use white text for contrast
    return Colors.white;
  }

  Color _getBorderColor(BuildContext context, MessageFilter filter, bool selected) {
    if (!selected) {
      return AppColors.neutralBorder(context);
    }

    switch (filter) {
      case MessageFilter.all:
        return AppColors.primaryColor(context);
      case MessageFilter.commands:
        return AppColors.infoColor(context);
      case MessageFilter.responses:
        return AppColors.successColor(context);
      case MessageFilter.errors:
        return AppColors.errorColor(context);
    }
  }
}

/// Extension on message list to filter messages.
extension MessageFilterExtension on List<Map<String, dynamic>> {
  /// Filter messages by the given filter type.
  List<Map<String, dynamic>> filterBy(MessageFilter filter) {
    switch (filter) {
      case MessageFilter.all:
        return this;
      case MessageFilter.commands:
        return where((m) => m['isCommand'] == true).toList();
      case MessageFilter.responses:
        return where((m) => m['isCommand'] != true && m['isError'] != true).toList();
      case MessageFilter.errors:
        return where((m) => m['isError'] == true).toList();
    }
  }

  /// Get counts for each filter type.
  Map<MessageFilter, int> getCounts() {
    return {
      MessageFilter.all: length,
      MessageFilter.commands: where((m) => m['isCommand'] == true).length,
      MessageFilter.responses:
          where((m) => m['isCommand'] != true && m['isError'] != true).length,
      MessageFilter.errors: where((m) => m['isError'] == true).length,
    };
  }
}
