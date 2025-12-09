import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design/design_system.dart';
import '../../models/command/command.dart';

/// A widget that displays a preview of the command that will be sent.
class CommandPreviewWidget extends StatelessWidget {
  /// The command being previewed.
  final DeviceCommand command;

  /// The current parameter values.
  final Map<String, String> parameterValues;

  /// Whether to show the copy button.
  final bool showCopyButton;

  /// Whether to show in compact mode.
  final bool compact;

  const CommandPreviewWidget({
    super.key,
    required this.command,
    required this.parameterValues,
    this.showCopyButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final commandString = command.buildCommandString(parameterValues);
    final isValid = _validateCommand();

    return Container(
      padding: compact
          ? EdgeInsets.all(DesignTokens.spacingS)
          : EdgeInsets.all(DesignTokens.spacingM),
      decoration: BoxDecoration(
        color: isValid
            ? colorScheme.primaryContainer.withValues(alpha: 0.2)
            : colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: DesignTokens.borderRadiusM,
        border: Border.all(
          color: isValid
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.code,
                size: compact ? DesignTokens.iconXS : DesignTokens.iconS,
                color: isValid ? colorScheme.primary : colorScheme.error,
              ),
              SizedBox(width: DesignTokens.spacingXS),
              Text(
                '指令預覽',
                style: TextStyle(
                  fontSize: compact ? DesignTokens.fontS : DesignTokens.fontM,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (showCopyButton && isValid)
                _CopyButton(
                  text: commandString,
                  compact: compact,
                ),
            ],
          ),
          SizedBox(height: compact ? DesignTokens.spacingXS : DesignTokens.spacingS),

          // Command string
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingSM,
              vertical: DesignTokens.spacingS,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: DesignTokens.borderRadiusS,
            ),
            child: SelectableText(
              commandString,
              style: TextStyle(
                fontSize: compact ? DesignTokens.fontM : DesignTokens.fontL,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                color: isValid ? colorScheme.onSurface : colorScheme.error,
              ),
            ),
          ),

          // Validation status
          if (!isValid) ...[
            SizedBox(height: DesignTokens.spacingS),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: DesignTokens.iconXS,
                  color: colorScheme.error,
                ),
                SizedBox(width: DesignTokens.spacingXS),
                Expanded(
                  child: Text(
                    _getValidationError() ?? '參數不完整',
                    style: TextStyle(
                      fontSize: DesignTokens.fontS,
                      color: colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _validateCommand() {
    final errors = command.validateParameters(parameterValues);
    return errors.isEmpty;
  }

  String? _getValidationError() {
    final errors = command.validateParameters(parameterValues);
    if (errors.isEmpty) return null;
    return errors.values.first;
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  final bool compact;

  const _CopyButton({
    required this.text,
    required this.compact,
  });

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  void _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() {
      _copied = true;
    });

    // Reset after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copyToClipboard,
        borderRadius: DesignTokens.borderRadiusS,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingS,
            vertical: DesignTokens.spacingXS,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _copied ? Icons.check : Icons.copy,
                size: widget.compact ? 14 : 16,
                color: _copied ? Colors.green : colorScheme.primary,
              ),
              if (!widget.compact) ...[
                SizedBox(width: DesignTokens.spacingXS),
                Text(
                  _copied ? '已複製' : '複製',
                  style: TextStyle(
                    fontSize: DesignTokens.fontS,
                    color: _copied ? Colors.green : colorScheme.primary,
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

/// A widget that displays command information with danger level warning.
class CommandInfoWidget extends StatelessWidget {
  /// The command to display info for.
  final DeviceCommand command;

  /// Whether to show in compact mode.
  final bool compact;

  const CommandInfoWidget({
    super.key,
    required this.command,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Command name and code
        Row(
          children: [
            Icon(
              command.icon,
              size: compact ? DesignTokens.iconS : DesignTokens.iconM,
              color: _getCategoryColor(context),
            ),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command.name,
                    style: TextStyle(
                      fontSize: compact ? DesignTokens.fontM : DesignTokens.fontL,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    command.command,
                    style: TextStyle(
                      fontSize: DesignTokens.fontS,
                      fontFamily: 'monospace',
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (!compact) ...[
          SizedBox(height: DesignTokens.spacingS),
          Text(
            command.description,
            style: TextStyle(
              fontSize: DesignTokens.fontM,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        // Danger warning
        if (command.dangerLevel != DangerLevel.safe) ...[
          SizedBox(height: DesignTokens.spacingS),
          _DangerWarning(
            dangerLevel: command.dangerLevel,
            warningMessage: command.warningMessage,
            compact: compact,
          ),
        ],
      ],
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
    }
  }
}

class _DangerWarning extends StatelessWidget {
  final DangerLevel dangerLevel;
  final String? warningMessage;
  final bool compact;

  const _DangerWarning({
    required this.dangerLevel,
    required this.warningMessage,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (icon, color, defaultMessage) = _getDangerInfo(colorScheme);

    return Container(
      padding: EdgeInsets.all(compact ? DesignTokens.spacingS : DesignTokens.spacingSM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: DesignTokens.borderRadiusS,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: compact ? DesignTokens.iconXS : DesignTokens.iconS,
            color: color,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Text(
              warningMessage ?? defaultMessage,
              style: TextStyle(
                fontSize: compact ? DesignTokens.fontS : DesignTokens.fontM,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _getDangerInfo(ColorScheme colorScheme) {
    switch (dangerLevel) {
      case DangerLevel.safe:
        return (Icons.check_circle, Colors.green, '安全操作');
      case DangerLevel.warning:
        return (Icons.warning_amber_rounded, Colors.orange, '此操作需要注意');
      case DangerLevel.dangerous:
        return (Icons.error_outline, colorScheme.error, '此為危險操作，請確認後再執行');
    }
  }
}
