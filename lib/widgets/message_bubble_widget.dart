import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/theme_service.dart';
import '../utils/responsive_utils.dart';

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
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
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
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        decoration: _getBubbleDecoration(context, isCommand, isError),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCommand) _buildCommandHeader(context),
            _buildMessageText(context, text, isCommand, isError),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.send,
            size: 14,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 4),
          Text(
            'Command',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
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
        top: 4,
        left: isCommand ? 0 : 8,
        right: isCommand ? 8 : 0,
      ),
      child: Text(
        _formatTimestamp(timestamp),
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary(context),
        ),
      ),
    );
  }

  BoxDecoration _getBubbleDecoration(BuildContext context, bool isCommand, bool isError) {
    if (isError) {
      return BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      );
    }

    if (isCommand) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }

    return BoxDecoration(
      color: AppColors.backgroundGradientStart(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.borderColor(context)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  Color _getTextColor(BuildContext context, bool isCommand, bool isError) {
    if (isError) return Colors.red.shade700;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      padding: const EdgeInsets.all(8),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundGradientStart(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a command to start the conversation',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 14,
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