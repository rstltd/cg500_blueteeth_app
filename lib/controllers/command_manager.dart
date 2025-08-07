import 'package:flutter/material.dart';
import '../controllers/simple_ble_controller.dart';
import '../utils/logger.dart';

/// Command manager for handling command history, input, and sending logic
class CommandManager {
  final SimpleBleController _controller;
  final TextEditingController _textController = TextEditingController();
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  
  // Callbacks for UI updates
  final VoidCallback? onCommandSent;
  final Function(Map<String, dynamic>)? onMessageAdded;

  CommandManager({
    required SimpleBleController controller,
    this.onCommandSent,
    this.onMessageAdded,
  }) : _controller = controller;

  /// Get the text controller for the input field
  TextEditingController get textController => _textController;
  
  /// Get command history
  List<String> get commandHistory => List.unmodifiable(_commandHistory);
  
  /// Get current history index
  int get historyIndex => _historyIndex;
  
  /// Check if device is connected
  bool get isConnected => _controller.connectedDevice != null;

  /// Send a command to the connected BLE device
  Future<void> sendCommand([String? commandText]) async {
    final command = commandText ?? _textController.text.trim();
    if (command.isEmpty || !isConnected) return;

    Logger.ui('Sending command: $command');

    // Add to history if it's a new command
    if (_commandHistory.isEmpty || _commandHistory.last != command) {
      _commandHistory.add(command);
      // Limit history to last 20 commands
      if (_commandHistory.length > 20) {
        _commandHistory.removeAt(0);
      }
    }
    _historyIndex = -1;

    // Add command message to chat
    final commandMessage = {
      'text': command,
      'isCommand': true,
      'timestamp': DateTime.now(),
    };
    onMessageAdded?.call(commandMessage);

    // Clear input if it was from text controller
    if (commandText == null) {
      _textController.clear();
    }
    
    onCommandSent?.call();

    // Send to BLE device
    final success = await _controller.sendCommand(command);
    if (!success) {
      Logger.ui('Failed to send command: $command');
      // Add error message to chat
      final errorMessage = {
        'text': 'Failed to send command',
        'isCommand': false,
        'isError': true,
        'timestamp': DateTime.now(),
      };
      onMessageAdded?.call(errorMessage);
    }
  }

  /// Navigate command history up (older commands)
  void historyUp() {
    if (_commandHistory.isEmpty) return;
    
    if (_historyIndex < _commandHistory.length - 1) {
      _historyIndex++;
      _textController.text = _commandHistory[_commandHistory.length - 1 - _historyIndex];
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    }
  }

  /// Navigate command history down (newer commands)
  void historyDown() {
    if (_commandHistory.isEmpty) return;
    
    if (_historyIndex > 0) {
      _historyIndex--;
      _textController.text = _commandHistory[_commandHistory.length - 1 - _historyIndex];
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
      );
    } else if (_historyIndex == 0) {
      _historyIndex = -1;
      _textController.clear();
    }
  }

  /// Get command suggestions based on history
  List<String> getCommandSuggestions(String input) {
    if (input.isEmpty) return _commandHistory.reversed.take(5).toList();
    
    return _commandHistory
        .where((cmd) => cmd.toLowerCase().contains(input.toLowerCase()))
        .toSet()
        .toList()
        .reversed
        .take(5)
        .toList();
  }

  /// Clear command history
  void clearHistory() {
    _commandHistory.clear();
    _historyIndex = -1;
  }

  /// Add predefined command to history and send
  Future<void> sendPredefinedCommand(String command) async {
    await sendCommand(command);
  }

  /// Dispose resources
  void dispose() {
    _textController.dispose();
  }
}