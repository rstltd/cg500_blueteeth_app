import 'package:flutter/material.dart';
import '../../design/design_system.dart';
import '../../models/command/device_command.dart';

/// A button widget for executing quick commands.
///
/// Displays a command button with icon and label that can be tapped
/// to execute the command. Supports loading and disabled states.
class QuickCommandButton extends StatelessWidget {
  /// The command to display and execute.
  final DeviceCommand command;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is in loading state.
  final bool isLoading;

  /// Whether to show the command label.
  final bool showLabel;

  /// Whether to use compact mode (smaller button).
  final bool compact;

  const QuickCommandButton({
    super.key,
    required this.command,
    this.onPressed,
    this.isLoading = false,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: '${command.name}. ${command.description}',
      hint: isLoading ? '執行中' : (isEnabled ? '點擊執行指令' : '目前無法使用'),
      child: Tooltip(
        message: command.description,
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
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
              color: isEnabled
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: DesignTokens.borderRadiusM,
              border: Border.all(
                color: isEnabled
                    ? colorScheme.primary.withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(context, isEnabled),
                if (showLabel) ...[
                  SizedBox(width: DesignTokens.spacingXS),
                  _buildLabel(context, isEnabled),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, bool isEnabled) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return SizedBox(
        width: compact ? DesignTokens.iconXS : DesignTokens.iconS,
        height: compact ? DesignTokens.iconXS : DesignTokens.iconS,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            colorScheme.onPrimaryContainer,
          ),
        ),
      );
    }

    return Icon(
      command.icon,
      size: compact ? DesignTokens.iconXS : DesignTokens.iconS,
      color: isEnabled
          ? colorScheme.onPrimaryContainer
          : colorScheme.onSurface.withValues(alpha: 0.38),
    );
  }

  Widget _buildLabel(BuildContext context, bool isEnabled) {
    final colorScheme = Theme.of(context).colorScheme;

    // Extract short label from command (remove $ prefix)
    final shortLabel = command.command.replaceFirst(r'$', '');

    return Text(
      shortLabel,
      style: TextStyle(
        fontSize: compact ? DesignTokens.fontS : DesignTokens.fontM,
        fontWeight: FontWeight.w500,
        color: isEnabled
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface.withValues(alpha: 0.38),
      ),
    );
  }
}

/// A variant of QuickCommandButton with an outline style.
class QuickCommandOutlineButton extends StatelessWidget {
  /// The command to display and execute.
  final DeviceCommand command;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is in loading state.
  final bool isLoading;

  /// Whether to show the command label.
  final bool showLabel;

  const QuickCommandOutlineButton({
    super.key,
    required this.command,
    this.onPressed,
    this.isLoading = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: '${command.name}. ${command.description}',
      hint: isLoading ? '執行中' : (isEnabled ? '點擊執行指令' : '目前無法使用'),
      child: Tooltip(
        message: command.description,
        child: OutlinedButton.icon(
          onPressed: isEnabled ? onPressed : null,
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
              : Icon(command.icon, size: DesignTokens.iconS),
          label: showLabel
              ? Text(command.command.replaceFirst(r'$', ''))
              : const SizedBox.shrink(),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingSM,
              vertical: DesignTokens.spacingS,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: DesignTokens.borderRadiusM,
            ),
          ),
        ),
      ),
    );
  }
}
