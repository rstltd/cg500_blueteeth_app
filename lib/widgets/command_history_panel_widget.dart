import 'package:flutter/material.dart';
import '../controllers/command_manager.dart';
import 'responsive_layout.dart';

/// Widget displaying command history for larger screens (tablet/desktop).
///
/// Features:
/// - Scrollable list of previous commands in reverse chronological order
/// - Replay button to re-use previous commands
/// - Responsive styling using app theme colors
class CommandHistoryPanelWidget extends StatelessWidget {
  const CommandHistoryPanelWidget({
    super.key,
    required this.commandManager,
  });

  final CommandManager commandManager;

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HistoryHeader(context: context),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: commandManager.commandHistory.isEmpty
                ? _EmptyHistoryMessage(context: context)
                : _HistoryList(commandManager: commandManager),
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
          'Command History',
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
        'No commands yet',
        fontSize: 14,
        color: AppColors.textSecondary(context),
      ),
    );
  }
}

/// Scrollable list of command history items.
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.commandManager});

  final CommandManager commandManager;

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
          onReplay: () {
            commandManager.textController.text = command;
          },
        );
      },
    );
  }
}

/// Single command history item with replay button.
class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.command,
    required this.onReplay,
  });

  final String command;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
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
              fontSize: 12,
              color: AppColors.textSecondary(context),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: onReplay,
            icon: Icon(
              Icons.replay,
              size: 16,
              color: AppColors.infoColor(context),
            ),
            tooltip: 'Use this command',
          ),
        ],
      ),
    );
  }
}
