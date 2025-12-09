import 'dart:async';
import 'package:flutter/material.dart';
import '../../design/design_system.dart';

/// Result of a command execution.
enum CommandResult {
  /// Command was sent successfully.
  success,

  /// Command sending failed.
  failure,

  /// Command is in progress.
  pending,
}

/// A widget that displays command execution feedback.
///
/// Shows a brief animated notification when a command is sent,
/// indicating success or failure.
class CommandFeedbackOverlay extends StatefulWidget {
  /// The result of the command execution.
  final CommandResult result;

  /// The command that was sent (optional, for display).
  final String? command;

  /// Custom message to display.
  final String? message;

  /// Duration to show the feedback.
  final Duration duration;

  /// Callback when the feedback is dismissed.
  final VoidCallback? onDismissed;

  const CommandFeedbackOverlay({
    super.key,
    required this.result,
    this.command,
    this.message,
    this.duration = const Duration(seconds: 2),
    this.onDismissed,
  });

  /// Show feedback as a SnackBar.
  static void showSnackBar(
    BuildContext context, {
    required CommandResult result,
    String? command,
    String? message,
    Duration duration = const Duration(seconds: 2),
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, bgColor, textColor, defaultMessage) = switch (result) {
      CommandResult.success => (
          Icons.check_circle,
          colorScheme.primaryContainer,
          colorScheme.onPrimaryContainer,
          '指令發送成功',
        ),
      CommandResult.failure => (
          Icons.error,
          colorScheme.errorContainer,
          colorScheme.onErrorContainer,
          '指令發送失敗',
        ),
      CommandResult.pending => (
          Icons.hourglass_empty,
          colorScheme.tertiaryContainer,
          colorScheme.onTertiaryContainer,
          '發送中...',
        ),
    };

    final displayMessage = message ?? defaultMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: DesignTokens.iconM),
            SizedBox(width: DesignTokens.spacingS),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayMessage,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (command != null) ...[
                    SizedBox(height: DesignTokens.spacingXS),
                    Text(
                      command,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontFamily: 'monospace',
                        fontSize: DesignTokens.fontS,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusM,
        ),
        duration: duration,
        margin: EdgeInsets.only(
          bottom: DesignTokens.spacingL,
          left: DesignTokens.spacingM,
          right: DesignTokens.spacingM,
        ),
      ),
    );
  }

  @override
  State<CommandFeedbackOverlay> createState() => _CommandFeedbackOverlayState();
}

class _CommandFeedbackOverlayState extends State<CommandFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto-dismiss after duration
    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, bgColor, iconColor, defaultMessage) = switch (widget.result) {
      CommandResult.success => (
          Icons.check_circle,
          colorScheme.primaryContainer,
          colorScheme.primary,
          '指令發送成功',
        ),
      CommandResult.failure => (
          Icons.error,
          colorScheme.errorContainer,
          colorScheme.error,
          '指令發送失敗',
        ),
      CommandResult.pending => (
          Icons.hourglass_empty,
          colorScheme.tertiaryContainer,
          colorScheme.tertiary,
          '發送中...',
        ),
    };

    final displayMessage = widget.message ?? defaultMessage;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.all(DesignTokens.spacingM),
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingM,
            vertical: DesignTokens.spacingSM,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: DesignTokens.borderRadiusM,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: DesignTokens.iconM),
              SizedBox(width: DesignTokens.spacingS),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayMessage,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.command != null) ...[
                      SizedBox(height: DesignTokens.spacingXS),
                      Text(
                        widget.command!,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                          fontSize: DesignTokens.fontS,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple inline feedback indicator for command buttons.
class CommandFeedbackIndicator extends StatelessWidget {
  /// The result of the command execution.
  final CommandResult result;

  /// Whether to show the indicator.
  final bool visible;

  /// Size of the indicator.
  final double size;

  const CommandFeedbackIndicator({
    super.key,
    required this.result,
    this.visible = true,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color) = switch (result) {
      CommandResult.success => (Icons.check_circle, colorScheme.primary),
      CommandResult.failure => (Icons.error, colorScheme.error),
      CommandResult.pending => (Icons.hourglass_empty, colorScheme.tertiary),
    };

    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Icon(icon, color: color, size: size),
    );
  }
}

/// Extension on BuildContext for easier feedback display.
extension CommandFeedbackExtension on BuildContext {
  /// Show command success feedback.
  void showCommandSuccess({String? command, String? message}) {
    CommandFeedbackOverlay.showSnackBar(
      this,
      result: CommandResult.success,
      command: command,
      message: message,
    );
  }

  /// Show command failure feedback.
  void showCommandFailure({String? command, String? message}) {
    CommandFeedbackOverlay.showSnackBar(
      this,
      result: CommandResult.failure,
      command: command,
      message: message,
    );
  }
}
