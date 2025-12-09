import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design/design_system.dart';

/// A reusable message bubble widget for chat-style communication
class MessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool showTimestamp;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCommand = message['isCommand'] ?? false;
    final bool isError = message['isError'] ?? false;
    final String text = message['text'] ?? '';
    final DateTime timestamp = message['timestamp'] ?? DateTime.now();

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: DesignTokens.spacingXS,
        horizontal: DesignTokens.spacingSM,
      ),
      child: Column(
        crossAxisAlignment: isCommand ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(context, text, isCommand, isError),
          if (showTimestamp) _buildTimestamp(context, timestamp, isCommand),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, String text, bool isCommand, bool isError) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final maxWidth = ResponsiveUtils.getCardMaxWidth(context) * 0.8;

    return GestureDetector(
      onLongPress: () => _copyToClipboard(context, text),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.all(isDesktop ? DesignTokens.spacingM : DesignTokens.spacingSM),
        decoration: _getBubbleDecoration(context, isCommand, isError),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCommand)
              _buildCommandHeader(context)
            else if (isError)
              _buildErrorHeader(context)
            else
              _buildResponseHeader(context),
            _buildMessageText(context, text, isCommand, isError),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingXS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.send,
            size: DesignTokens.fontM,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            'Command',
            style: AppTextStyles.captionSmall(context).copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingXS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: DesignTokens.fontM,
            color: AppColors.errorColor(context),
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            'Error',
            style: AppTextStyles.captionSmall(context).copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.errorColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacingXS),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back,
            size: DesignTokens.fontM,
            color: AppColors.successColor(context),
          ),
          SizedBox(width: DesignTokens.spacingXS),
          Text(
            'Response',
            style: AppTextStyles.captionSmall(context).copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.successColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageText(BuildContext context, String text, bool isCommand, bool isError) {
    return SelectableText(
      text,
      style: TextStyle(
        fontSize: ResponsiveUtils.getFontSize(context, base: 14),
        color: _getTextColor(context, isCommand, isError),
        fontFamily: text.contains(RegExp(r'[0-9A-Fa-f]{2,}')) ? 'monospace' : null,
        height: 1.4,
      ),
    );
  }

  Widget _buildTimestamp(BuildContext context, DateTime timestamp, bool isCommand) {
    return Container(
      margin: EdgeInsets.only(
        top: DesignTokens.spacingXS,
        left: isCommand ? 0 : DesignTokens.spacingS,
        right: isCommand ? DesignTokens.spacingS : 0,
      ),
      child: Text(
        _formatTimestamp(timestamp),
        style: AppTextStyles.captionSmall(context),
      ),
    );
  }

  BoxDecoration _getBubbleDecoration(BuildContext context, bool isCommand, bool isError) {
    if (isError) {
      return BoxDecoration(
        color: AppColors.errorContainer(context),
        borderRadius: DesignTokens.borderRadiusL,
        border: Border.all(color: AppColors.errorBorder(context)),
      );
    }

    if (isCommand) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.commandGradientStart(context),
            AppColors.commandGradientEnd(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: DesignTokens.borderRadiusL,
        boxShadow: DesignTokens.cardShadow(context),
      );
    }

    return BoxDecoration(
      color: AppColors.backgroundGradientStart(context),
      borderRadius: DesignTokens.borderRadiusL,
      border: Border.all(color: AppColors.borderColor(context)),
      boxShadow: DesignTokens.subtleShadow(context),
    );
  }

  Color _getTextColor(BuildContext context, bool isCommand, bool isError) {
    if (isError) return AppColors.onErrorContainer(context);
    if (isCommand) return Colors.white;
    return AppColors.textPrimary(context);
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message copied to clipboard'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: DesignTokens.borderRadiusS),
      ),
    );
  }
}

/// A widget that displays a list of message bubbles with auto-scrolling
class MessageListWidget extends StatefulWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController? scrollController;
  final bool autoScroll;

  const MessageListWidget({
    super.key,
    required this.messages,
    this.scrollController,
    this.autoScroll = true,
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
  void didUpdateWidget(MessageListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll && widget.messages.length > oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
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
        return MessageBubbleWidget(
          message: widget.messages[index],
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
            'No messages yet',
            style: AppTextStyles.titleMedium(context),
          ),
          SizedBox(height: DesignTokens.spacingS),
          Text(
            'Send a command to start the conversation',
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