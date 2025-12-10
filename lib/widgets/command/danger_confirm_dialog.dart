import 'package:flutter/material.dart';
import '../../design/design_system.dart';
import '../../models/command/command.dart';

/// A danger confirmation dialog for dangerous commands.
///
/// Shows a warning dialog when executing commands with [DangerLevel.dangerous].
/// Displays the command name, warning message (if any), and the command string
/// that will be sent to the device.
class DangerConfirmDialog extends StatelessWidget {
  /// The command that requires confirmation.
  final DeviceCommand command;

  /// The command string that will be sent.
  final String commandString;

  const DangerConfirmDialog({
    super.key,
    required this.command,
    required this.commandString,
  });

  /// Shows the danger confirmation dialog.
  /// Returns true if confirmed, false if cancelled.
  static Future<bool> show({
    required BuildContext context,
    required DeviceCommand command,
    required String commandString,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DangerConfirmDialog(
        command: command,
        commandString: commandString,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dangerLevel = command.dangerLevel;

    // Use warning-appropriate colors for warning level
    final iconColor = dangerLevel == DangerLevel.warning
        ? Colors.orange
        : colorScheme.error;
    final buttonColor = dangerLevel == DangerLevel.warning
        ? Colors.orange
        : colorScheme.error;

    return AlertDialog(
      icon: Icon(
        dangerLevel.icon,
        size: 48,
        color: iconColor,
      ),
      title: Text(dangerLevel.confirmationTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            command.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: DesignTokens.fontL,
            ),
          ),
          SizedBox(height: DesignTokens.spacingS),
          if (command.warningMessage != null) ...[
            Container(
              padding: EdgeInsets.all(DesignTokens.spacingSM),
              decoration: BoxDecoration(
                color: dangerLevel == DangerLevel.warning
                    ? Colors.orange.withValues(alpha: 0.15)
                    : colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: DesignTokens.borderRadiusS,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: DesignTokens.iconS,
                    color: iconColor,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      command.warningMessage!,
                      style: TextStyle(
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: DesignTokens.spacingM),
          ],
          Text(
            '將發送以下指令:',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: DesignTokens.spacingXS),
          Container(
            padding: EdgeInsets.all(DesignTokens.spacingSM),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: DesignTokens.borderRadiusS,
            ),
            child: Text(
              commandString,
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor,
          ),
          child: Text(dangerLevel.confirmButtonText),
        ),
      ],
    );
  }
}
