import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design/design_system.dart';
import '../../l10n/app_strings.dart';

/// A compact log entry widget for terminal-style communication display.
///
/// Layout per row (~30px height):
/// [HH:mm:ss]  [arrow] [TYPE]  [message text...]
class LogEntryWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final int index;

  const LogEntryWidget({
    super.key,
    required this.message,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCommand = message['isCommand'] ?? false;
    final bool isError = message['isError'] ?? false;
    final String text = message['text'] ?? '';
    final DateTime timestamp = message['timestamp'] ?? DateTime.now();

    return GestureDetector(
      onLongPress: () => _copyToClipboard(context, text),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: DesignTokens.spacingXS,
          horizontal: DesignTokens.spacingS,
        ),
        color: index.isEven
            ? Colors.transparent
            : AppColors.backgroundGradientStart(context).withValues(alpha: 0.3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.textSecondary(context),
              ),
            ),
            SizedBox(width: DesignTokens.spacingS),
            // Type indicator
            _buildTypeIndicator(context, isCommand, isError),
            SizedBox(width: DesignTokens.spacingS),
            // Message text
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: isError
                      ? AppColors.errorColor(context)
                      : AppColors.textPrimary(context),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeIndicator(
      BuildContext context, bool isCommand, bool isError) {
    final String arrow;
    final String label;
    final Color color;

    if (isError) {
      arrow = 'x';
      label = 'ERR';
      color = AppColors.errorColor(context);
    } else if (isCommand) {
      arrow = '->';
      label = 'CMD';
      color = AppColors.infoColor(context);
    } else {
      arrow = '<-';
      label = 'RSP';
      color = AppColors.successColor(context);
    }

    return Text(
      '$arrow $label',
      style: TextStyle(
        fontSize: 12,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已複製訊息到剪貼簿'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusS),
      ),
    );
  }
}

/// A widget that displays a list of log entries.
class MessageListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController? scrollController;

  const MessageListWidget({
    super.key,
    required this.messages,
    this.scrollController,
  });

  @override
  State<MessageListWidget> createState() => _MessageListWidgetState();
}

class _MessageListWidgetState extends State<MessageListWidget> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: DesignTokens.paddingS,
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        return LogEntryWidget(
          message: widget.messages[index],
          index: index,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: DesignTokens.paddingL,
            decoration: BoxDecoration(
              color: AppColors.backgroundGradientStart(context),
              borderRadius: DesignTokens.borderRadiusXL,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: DesignTokens.iconXL,
              color: AppColors.textSecondary(context),
            ),
          ),
          SizedBox(height: DesignTokens.spacingM),
          Text(
            AppStrings.noMessagesYet,
            style: AppTextStyles.titleMedium(context),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            AppStrings.sendCommandToStart,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
}
