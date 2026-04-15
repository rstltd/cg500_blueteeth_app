import 'package:flutter/material.dart';
import '../../controllers/command_manager.dart';
import '../../l10n/app_strings.dart';
import '../layout/responsive_layout.dart';

/// Widget displaying command history.
///
/// Sidebar mode (tablet/desktop): scrollable list with two action buttons per
/// item — fill the input field, or send immediately.
/// Single-tap mode (mobile bottom sheet): tap any row to send immediately.
class CommandHistoryPanelWidget extends StatelessWidget {
  const CommandHistoryPanelWidget({
    super.key,
    required this.commandManager,
    this.onSendNow,
    this.singleTapMode = false,
    this.height = 200,
  });

  final CommandManager commandManager;

  /// Optional callback to send a history command immediately. When null,
  /// only the fill-input action is shown (legacy behavior).
  final Future<bool> Function(String command)? onSendNow;

  /// When true, the whole row is tappable and dispatches [onSendNow]
  /// instead of showing per-row buttons. Used for mobile bottom sheets
  /// where horizontal space is tight.
  final bool singleTapMode;

  /// Visible height of the scrollable list area.
  final double height;

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HistoryHeader(context: context),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: commandManager.commandHistory.isEmpty
                ? _EmptyHistoryMessage(context: context)
                : _HistoryList(
                    commandManager: commandManager,
                    onSendNow: onSendNow,
                    singleTapMode: singleTapMode,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Header row with history icon and title.
class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Row(
      children: [
        ResponsiveIcon(
          Icons.history,
          size: 20,
          color: AppColors.infoColor(context),
        ),
        const SizedBox(width: 8),
        ResponsiveText(
          AppStrings.commandHistory,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary(context),
        ),
      ],
    );
  }
}

/// Message shown when no commands have been sent yet.
class _EmptyHistoryMessage extends StatelessWidget {
  const _EmptyHistoryMessage({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Center(
      child: ResponsiveText(
        AppStrings.noCommandsYet,
        fontSize: 14,
        color: AppColors.textSecondary(context),
      ),
    );
  }
}

/// Scrollable list of command history items.
class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.commandManager,
    required this.onSendNow,
    required this.singleTapMode,
  });

  final CommandManager commandManager;
  final Future<bool> Function(String)? onSendNow;
  final bool singleTapMode;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: commandManager.commandHistory.length,
      reverse: true,
      itemBuilder: (context, index) {
        final reversedIndex = commandManager.commandHistory.length - 1 - index;
        final command = commandManager.commandHistory[reversedIndex];
        return _HistoryItem(
          command: command,
          onFillInput: () {
            commandManager.textController.text = command;
          },
          onSendNow: onSendNow == null ? null : () => onSendNow!(command),
          singleTapMode: singleTapMode,
        );
      },
    );
  }
}

/// Single command history item.
///
/// In dual-button mode (sidebar) shows separate "fill input" and "send now"
/// buttons. In single-tap mode (mobile bottom sheet) the whole row is
/// tappable and dispatches [onSendNow].
class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.command,
    required this.onFillInput,
    required this.onSendNow,
    required this.singleTapMode,
  });

  final String command;
  final VoidCallback onFillInput;
  final VoidCallback? onSendNow;
  final bool singleTapMode;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: singleTapMode ? 14 : 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundGradientStart(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: ResponsiveText(
              command,
              fontSize: singleTapMode ? 14 : 12,
              color: AppColors.textPrimary(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (singleTapMode)
            Icon(
              Icons.send,
              size: 18,
              color: AppColors.infoColor(context),
            )
          else ...[
            IconButton(
              onPressed: onFillInput,
              icon: Icon(
                Icons.edit_note,
                size: 18,
                color: AppColors.textSecondary(context),
              ),
              tooltip: AppStrings.historyFillInputTooltip,
              visualDensity: VisualDensity.compact,
            ),
            if (onSendNow != null)
              IconButton(
                onPressed: onSendNow,
                icon: Icon(
                  Icons.send,
                  size: 18,
                  color: AppColors.infoColor(context),
                ),
                tooltip: AppStrings.historySendNowTooltip,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ],
      ),
    );

    if (singleTapMode && onSendNow != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSendNow,
          borderRadius: BorderRadius.circular(8),
          child: row,
        ),
      );
    }
    return row;
  }
}
