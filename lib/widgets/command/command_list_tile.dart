import 'package:flutter/material.dart';
import '../../design/design_system.dart';
import '../../models/command/command.dart';

/// A list tile widget for displaying a device command.
///
/// Shows the command icon, name, description, and danger indicator.
/// Tapping the tile triggers the [onTap] callback.
class CommandListTile extends StatelessWidget {
  /// The command to display.
  final DeviceCommand command;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  /// Whether this tile is currently selected.
  final bool isSelected;

  /// Whether to show the command string.
  final bool showCommandString;

  /// Whether to use compact mode.
  final bool compact;

  const CommandListTile({
    super.key,
    required this.command,
    this.onTap,
    this.isSelected = false,
    this.showCommandString = true,
    this.compact = false,
  });

  String _buildSemanticLabel() {
    final parts = <String>[command.name, command.description];
    if (command.hasParameters) parts.add('需要參數');
    if (command.dangerLevel == DangerLevel.warning) parts.add('需注意');
    if (command.dangerLevel == DangerLevel.dangerous) parts.add('危險操作');
    return parts.join('. ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onTap != null;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: _buildSemanticLabel(),
      hint: isEnabled ? '點擊選擇此指令' : '目前無法使用',
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
        onTap: onTap,
        borderRadius: DesignTokens.borderRadiusM,
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          curve: DesignTokens.curveStandard,
          padding: compact
              ? EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingS,
                )
              : EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingSM,
                  vertical: DesignTokens.spacingSM,
                ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: DesignTokens.borderRadiusM,
            border: isSelected
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Command icon with category color
              _buildIcon(context, isEnabled),
              SizedBox(width: DesignTokens.spacingSM),

              // Command info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Command name and string
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            command.name,
                            style: TextStyle(
                              fontSize: compact
                                  ? DesignTokens.fontM
                                  : DesignTokens.fontL,
                              fontWeight: FontWeight.w500,
                              color: isEnabled
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurface
                                      .withValues(alpha: DesignTokens.opacityDisabled),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showCommandString) ...[
                          SizedBox(width: DesignTokens.spacingS),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacingS,
                              vertical: DesignTokens.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: DesignTokens.borderRadiusS,
                            ),
                            child: Text(
                              command.command,
                              style: TextStyle(
                                fontSize: DesignTokens.fontS,
                                fontFamily: 'monospace',
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Description
                    if (!compact) ...[
                      SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        command.description,
                        style: TextStyle(
                          fontSize: DesignTokens.fontS,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Parameter and danger indicators
                    if (!compact && (command.hasParameters || command.requiresConfirmation)) ...[
                      SizedBox(height: DesignTokens.spacingS),
                      _buildIndicators(context),
                    ],
                  ],
                ),
              ),

              // Chevron
              SizedBox(width: DesignTokens.spacingS),
              Icon(
                Icons.chevron_right,
                size: DesignTokens.iconS,
                color: isEnabled
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface.withValues(alpha: DesignTokens.opacityDisabled),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, bool isEnabled) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = _getCategoryColor(context);

    return Container(
      width: compact ? 36 : 44,
      height: compact ? 36 : 44,
      decoration: BoxDecoration(
        color: isEnabled
            ? categoryColor.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest,
        borderRadius: DesignTokens.borderRadiusM,
      ),
      child: Center(
        child: Icon(
          command.icon,
          size: compact ? DesignTokens.iconS : DesignTokens.iconM,
          color: isEnabled
              ? categoryColor
              : colorScheme.onSurface.withValues(alpha: DesignTokens.opacityDisabled),
        ),
      ),
    );
  }

  Widget _buildIndicators(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final indicators = <Widget>[];

    // Parameter indicator
    if (command.hasParameters) {
      indicators.add(
        _buildChip(
          context,
          icon: Icons.edit_note,
          label: '需要參數',
          color: colorScheme.primary,
        ),
      );
    }

    // Danger indicator
    if (command.dangerLevel == DangerLevel.warning) {
      indicators.add(
        _buildChip(
          context,
          icon: Icons.warning_amber_rounded,
          label: '需注意',
          color: Colors.orange,
        ),
      );
    } else if (command.dangerLevel == DangerLevel.dangerous) {
      indicators.add(
        _buildChip(
          context,
          icon: Icons.error_outline,
          label: '危險操作',
          color: colorScheme.error,
        ),
      );
    }

    if (indicators.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: DesignTokens.spacingS,
      runSpacing: DesignTokens.spacingXS,
      children: indicators,
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: DesignTokens.borderRadiusS,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: DesignTokens.fontS,
            color: color,
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            label,
            style: TextStyle(
              fontSize: DesignTokens.fontCaption,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (command.category) {
      case CommandCategory.query:
        return colorScheme.primary;
      case CommandCategory.config:
        return colorScheme.tertiary;
      case CommandCategory.control:
        return Colors.orange;
      case CommandCategory.debug:
        return colorScheme.secondary;
      case CommandCategory.custom:
        return Colors.deepOrange;
    }
  }
}

/// A compact command tile for use in lists with limited space.
class CompactCommandListTile extends StatelessWidget {
  /// The command to display.
  final DeviceCommand command;

  /// Callback when the tile is tapped.
  final VoidCallback? onTap;

  /// Whether this tile is currently selected.
  final bool isSelected;

  const CompactCommandListTile({
    super.key,
    required this.command,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return CommandListTile(
      command: command,
      onTap: onTap,
      isSelected: isSelected,
      showCommandString: false,
      compact: true,
    );
  }
}
