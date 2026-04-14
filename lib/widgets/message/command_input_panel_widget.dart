import 'package:flutter/material.dart';
import '../../controllers/ble_controller_interface.dart';
import '../../controllers/command_manager.dart';
import '../../models/ble_device.dart';
import '../../l10n/app_strings.dart';

/// Widget for entering and sending BLE commands with history navigation.
///
/// Features:
/// - Text input field with visual feedback based on connection state
/// - Send button with animated styling
/// - Command history navigation (up/down arrows)
/// - Ready status indicator
class CommandInputPanelWidget extends StatelessWidget {
  const CommandInputPanelWidget({
    super.key,
    required this.controller,
    required this.commandManager,
    required this.onSendCommand,
    required this.onNavigateHistory,
    this.canManualInput = true,
  });

  final BleControllerInterface controller;
  final CommandManager commandManager;
  final VoidCallback onSendCommand;
  final void Function(bool up) onNavigateHistory;

  /// Whether manual command input is permitted for the current user role.
  /// When false, the text field, send button, and history navigation are
  /// fully disabled even if the device is connected.
  final bool canManualInput;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: StreamBuilder<BleDeviceModel?>(
        stream: controller.connectedDeviceStream,
        builder: (context, snapshot) {
          final isConnected =
              snapshot.hasData || controller.connectedDevice != null;
          final commandInfo = controller.getCommandInfo();
          final hasChannel = commandInfo['hasCommandChannel'] ?? false;
          final canSendCommands = isConnected && hasChannel && canManualInput;

          // Disabled-state hint depends on WHY input is blocked: connection
          // first, then role.
          final String disabledHint = !isConnected
              ? AppStrings.connectToSendCommands
              : !canManualInput
                  ? AppStrings.needDeveloperMode
                  : AppStrings.connectToSendCommands;

          return Column(
            children: [
              _CommandInputRow(
                commandManager: commandManager,
                canSendCommands: canSendCommands,
                disabledHint: disabledHint,
                onSendCommand: onSendCommand,
              ),
              if (commandManager.commandHistory.isNotEmpty) ...[
                const SizedBox(height: 12),
                _HistoryNavigationRow(
                  commandManager: commandManager,
                  canSendCommands: canSendCommands,
                  onNavigateHistory: onNavigateHistory,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Row containing the text input and send button.
class _CommandInputRow extends StatelessWidget {
  const _CommandInputRow({
    required this.commandManager,
    required this.canSendCommands,
    required this.disabledHint,
    required this.onSendCommand,
  });

  final CommandManager commandManager;
  final bool canSendCommands;
  final String disabledHint;
  final VoidCallback onSendCommand;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CommandTextField(
            controller: commandManager.textController,
            canSendCommands: canSendCommands,
            disabledHint: disabledHint,
            onSubmitted: onSendCommand,
          ),
        ),
        const SizedBox(width: 12),
        _SendButton(
          canSendCommands: canSendCommands,
          onPressed: onSendCommand,
        ),
      ],
    );
  }
}

/// Text field for command input.
class _CommandTextField extends StatelessWidget {
  const _CommandTextField({
    required this.controller,
    required this.canSendCommands,
    required this.disabledHint,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool canSendCommands;
  final String disabledHint;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color:
              canSendCommands ? Colors.blue.shade200 : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: canSendCommands,
        decoration: InputDecoration(
          hintText:
              canSendCommands ? AppStrings.enterCommand : disabledHint,
          hintStyle: TextStyle(
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          prefixIcon: Icon(
            Icons.keyboard,
            color: canSendCommands ? Colors.blue.shade600 : Colors.grey.shade400,
          ),
        ),
        onSubmitted: canSendCommands ? (_) => onSubmitted() : null,
        style: const TextStyle(
          fontSize: 16,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// Animated send button.
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.canSendCommands,
    required this.onPressed,
  });

  final bool canSendCommands;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: canSendCommands ? Colors.blue.shade500 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(25),
        boxShadow: canSendCommands
            ? [
                BoxShadow(
                  color: Colors.blue.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: IconButton(
        onPressed: canSendCommands ? onPressed : null,
        icon: Icon(
          Icons.send_rounded,
          color: canSendCommands ? Colors.white : Colors.grey.shade500,
        ),
        iconSize: 24,
      ),
    );
  }
}

/// Row with history navigation controls and ready status.
class _HistoryNavigationRow extends StatelessWidget {
  const _HistoryNavigationRow({
    required this.commandManager,
    required this.canSendCommands,
    required this.onNavigateHistory,
  });

  final CommandManager commandManager;
  final bool canSendCommands;
  final void Function(bool up) onNavigateHistory;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HistoryNavigationButtons(
          canSendCommands: canSendCommands,
          onNavigateHistory: onNavigateHistory,
        ),
        const SizedBox(width: 12),
        _HistoryCountIndicator(
          count: commandManager.commandHistory.length,
        ),
        const Spacer(),
        if (canSendCommands) const _ReadyIndicator(),
      ],
    );
  }
}

/// Up/down arrow buttons for history navigation.
class _HistoryNavigationButtons extends StatelessWidget {
  const _HistoryNavigationButtons({
    required this.canSendCommands,
    required this.onNavigateHistory,
  });

  final bool canSendCommands;
  final void Function(bool up) onNavigateHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: canSendCommands ? () => onNavigateHistory(true) : null,
            tooltip: AppStrings.previousCommand,
            iconSize: 20,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: canSendCommands ? () => onNavigateHistory(false) : null,
            tooltip: AppStrings.nextCommand,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

/// Shows history icon and command count.
class _HistoryCountIndicator extends StatelessWidget {
  const _HistoryCountIndicator({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.history,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          '$count 個指令',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Green "Ready" indicator shown when commands can be sent.
class _ReadyIndicator extends StatelessWidget {
  const _ReadyIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.radio_button_checked,
            size: 12,
            color: Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            AppStrings.ready,
            style: TextStyle(
              fontSize: 11,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
