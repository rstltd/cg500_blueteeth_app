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

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 48,
        color: colorScheme.error,
      ),
      title: Text('確認執行危險操作'),
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
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: DesignTokens.borderRadiusS,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: DesignTokens.iconS,
                    color: colorScheme.error,
                  ),
                  SizedBox(width: DesignTokens.spacingS),
                  Expanded(
                    child: Text(
                      command.warningMessage!,
                      style: TextStyle(
                        color: colorScheme.error,
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
            backgroundColor: colorScheme.error,
          ),
          child: Text('確認執行'),
        ),
      ],
    );
  }
}
