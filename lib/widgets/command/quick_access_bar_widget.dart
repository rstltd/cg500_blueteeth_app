import 'package:flutter/material.dart';
import '../../core/interfaces/command_repository_interface.dart';
import '../../design/design_system.dart';
import '../../models/command/device_command.dart';
import 'quick_command_button.dart';

/// A horizontal bar displaying quick access command buttons.
///
/// Shows commonly used commands that don't require parameters and are safe
/// to execute. Includes a button to open the full command menu.
class QuickAccessBarWidget extends StatelessWidget {
  /// The command repository to get quick access commands from.
  final CommandRepositoryInterface repository;

  /// Callback when a command is selected.
  final ValueChanged<DeviceCommand> onCommandSelected;

  /// Callback when the command menu button is pressed.
  final VoidCallback onOpenCommandMenu;

  /// The currently executing command (if any).
  final String? executingCommand;

  /// Whether the device is connected.
  final bool isConnected;

  /// Whether to use compact mode.
  final bool compact;

  const QuickAccessBarWidget({
    super.key,
    required this.repository,
    required this.onCommandSelected,
    required this.onOpenCommandMenu,
    this.executingCommand,
    this.isConnected = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final quickCommands = repository.getQuickAccessCommands();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingSM,
        vertical: DesignTokens.spacingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: DesignTokens.dividerThickness,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick command buttons
            ...quickCommands.map((command) => Padding(
                  padding: EdgeInsets.only(right: DesignTokens.spacingS),
                  child: QuickCommandButton(
                    command: command,
                    onPressed: isConnected
                        ? () => onCommandSelected(command)
                        : null,
                    isLoading: executingCommand == command.command,
                    compact: compact,
                  ),
                )),

            // Divider
            Container(
              width: DesignTokens.dividerThickness,
              height: compact ? 24 : 32,
              color: colorScheme.outlineVariant,
              margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacingS),
            ),

            // Command menu button
            _buildMenuButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: '開啟指令選單',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isConnected ? onOpenCommandMenu : null,
          borderRadius: DesignTokens.borderRadiusM,
          child: AnimatedContainer(
            duration: DesignTokens.durationFast,
            curve: DesignTokens.curveStandard,
            padding: compact
                ? EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingS,
                    vertical: DesignTokens.spacingXS,
                  )
                : EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingSM,
                    vertical: DesignTokens.spacingS,
                  ),
            decoration: BoxDecoration(
              color: isConnected
                  ? colorScheme.secondaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: DesignTokens.borderRadiusM,
              border: Border.all(
                color: isConnected
                    ? colorScheme.secondary.withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.apps,
                  size: compact ? DesignTokens.iconXS : DesignTokens.iconS,
                  color: isConnected
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onSurface.withValues(alpha: 0.38),
                ),
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  '更多',
                  style: TextStyle(
                    fontSize:
                        compact ? DesignTokens.fontS : DesignTokens.fontM,
                    fontWeight: FontWeight.w500,
                    color: isConnected
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact version of the quick access bar that only shows icons.
class CompactQuickAccessBar extends StatelessWidget {
  /// The command repository to get quick access commands from.
  final CommandRepositoryInterface repository;

  /// Callback when a command is selected.
  final ValueChanged<DeviceCommand> onCommandSelected;

  /// Callback when the command menu button is pressed.
  final VoidCallback onOpenCommandMenu;

  /// The currently executing command (if any).
  final String? executingCommand;

  /// Whether the device is connected.
  final bool isConnected;

  const CompactQuickAccessBar({
    super.key,
    required this.repository,
    required this.onCommandSelected,
    required this.onOpenCommandMenu,
    this.executingCommand,
    this.isConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    final quickCommands = repository.getQuickAccessCommands();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingS,
        vertical: DesignTokens.spacingXS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: DesignTokens.dividerThickness,
          ),
        ),
      ),
      child: Row(
        children: [
          // Quick command icon buttons
          Expanded(
            child: Wrap(
              spacing: DesignTokens.spacingXS,
              children: quickCommands
                  .map((command) => _buildIconButton(
                        context,
                        command,
                        colorScheme,
                      ))
                  .toList(),
            ),
          ),

          // Menu button
          IconButton(
            onPressed: isConnected ? onOpenCommandMenu : null,
            icon: Icon(
              Icons.more_horiz,
              color: isConnected
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
            tooltip: '指令選單',
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: DesignTokens.borderRadiusS,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    DeviceCommand command,
    ColorScheme colorScheme,
  ) {
    final isLoading = executingCommand == command.command;

    return Tooltip(
      message: '${command.name}\n${command.description}',
      child: IconButton(
        onPressed:
            isConnected && !isLoading ? () => onCommandSelected(command) : null,
        icon: isLoading
            ? SizedBox(
                width: DesignTokens.iconS,
                height: DesignTokens.iconS,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              )
            : Icon(
                command.icon,
                color: isConnected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.38),
              ),
        style: IconButton.styleFrom(
          backgroundColor: isConnected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusS,
          ),
        ),
      ),
    );
  }
}

/// A floating quick access bar that can be positioned anywhere.
class FloatingQuickAccessBar extends StatelessWidget {
  /// The command repository to get quick access commands from.
  final CommandRepositoryInterface repository;

  /// Callback when a command is selected.
  final ValueChanged<DeviceCommand> onCommandSelected;

  /// Callback when the command menu button is pressed.
  final VoidCallback onOpenCommandMenu;

  /// The currently executing command (if any).
  final String? executingCommand;

  /// Whether the device is connected.
  final bool isConnected;

  const FloatingQuickAccessBar({
    super.key,
    required this.repository,
    required this.onCommandSelected,
    required this.onOpenCommandMenu,
    this.executingCommand,
    this.isConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: DesignTokens.borderRadiusL,
        boxShadow: DesignTokens.elevatedShadow(context),
      ),
      child: ClipRRect(
        borderRadius: DesignTokens.borderRadiusL,
        child: QuickAccessBarWidget(
          repository: repository,
          onCommandSelected: onCommandSelected,
          onOpenCommandMenu: onOpenCommandMenu,
          executingCommand: executingCommand,
          isConnected: isConnected,
        ),
      ),
    );
  }
}
