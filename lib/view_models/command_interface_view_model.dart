import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../controllers/command_manager.dart';
import '../core/service_locator.dart' show getIt;
import '../core/view_model/view_model.dart';
import '../utils/logger.dart';

/// ViewModel for the Command Interface View.
///
/// Manages:
/// - BLE controller initialization
/// - Message history
/// - Command responses from BLE device
/// - Scroll controller for auto-scrolling
///
/// Example usage:
/// ```dart
/// ViewModelProvider<CommandInterfaceViewModel>(
///   create: () => CommandInterfaceViewModel(),
///   builder: (context, viewModel, child) {
///     return CommandInterfaceContent(viewModel: viewModel);
///   },
/// )
/// ```
class CommandInterfaceViewModel extends BaseViewModel with MountedAwareMixin {
  /// Creates a CommandInterfaceViewModel.
  ///
  /// [controller] - Optional BLE controller for dependency injection (testing).
  /// If null, the controller is retrieved from the service locator.
  CommandInterfaceViewModel({
    BleControllerInterface? controller,
  }) : _injectedController = controller;

  final BleControllerInterface? _injectedController;
  late final BleControllerInterface _controller;
  late final CommandManager _commandManager;
  final ScrollController _scrollController = ScrollController();
  final List<MessageData> _messages = [];

  /// The BLE controller instance.
  BleControllerInterface get controller => _controller;

  /// The command manager for sending commands.
  CommandManager get commandManager => _commandManager;

  /// Scroll controller for the message list.
  ScrollController get scrollController => _scrollController;

  /// List of messages (commands and responses).
  List<MessageData> get messages => List.unmodifiable(_messages);

  /// Whether there are any messages.
  bool get hasMessages => _messages.isNotEmpty;

  /// Number of messages.
  int get messageCount => _messages.length;

  @override
  Future<void> onInit() async {
    // Use injected controller or get from service locator
    _controller = _injectedController ?? getIt<BleControllerInterface>();

    // Create command manager with callbacks
    _commandManager = CommandManager(
      controller: _controller,
      onCommandSent: _scrollToBottom,
      onMessageAdded: _onMessageFromCommandManager,
    );

    // Initialize controller if needed
    await _ensureControllerInitialized();

    // Subscribe to command responses
    subscribe<String>(
      _controller.commandResponseStream,
      _onCommandResponse,
    );
  }

  Future<void> _ensureControllerInitialized() async {
    if (!_controller.isInitialized) {
      final success = await _controller.initialize();
      Logger.ui('Controller initialized = $success');
    } else {
      Logger.ui('Controller already initialized');
    }

    // Log connection status
    final connectedDevice = _controller.connectedDevice;
    if (connectedDevice != null) {
      Logger.ui('Connected to: ${connectedDevice.displayName}');
    }
  }

  void _onCommandResponse(String response) {
    addMessage(MessageData(
      text: response,
      isCommand: false,
      timestamp: DateTime.now(),
    ));
  }

  void _onMessageFromCommandManager(Map<String, dynamic> messageMap) {
    addMessage(MessageData.fromMap(messageMap));
  }

  /// Add a message to the list.
  void addMessage(MessageData message) {
    _messages.add(message);
    safeNotifyListeners();
    _scrollToBottom();
  }

  /// Clear all messages.
  void clearMessages() {
    _messages.clear();
    safeNotifyListeners();
  }

  /// Send the current command.
  Future<void> sendCommand() async {
    await _commandManager.sendCommand();
  }

  /// Navigate command history up.
  void historyUp() {
    _commandManager.historyUp();
  }

  /// Navigate command history down.
  void historyDown() {
    _commandManager.historyDown();
  }

  /// Navigate command history.
  void navigateHistory(bool up) {
    if (up) {
      historyUp();
    } else {
      historyDown();
    }
  }

  void _scrollToBottom() {
    // Use post-frame callback to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && isMounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onDispose() {
    _commandManager.dispose();
    _scrollController.dispose();
    super.onDispose();
  }
}

/// Immutable data class for a message.
class MessageData {
  const MessageData({
    required this.text,
    required this.isCommand,
    required this.timestamp,
    this.isError = false,
  });

  /// Create from a Map (for compatibility with existing code).
  factory MessageData.fromMap(Map<String, dynamic> map) {
    return MessageData(
      text: map['text'] as String? ?? '',
      isCommand: map['isCommand'] as bool? ?? false,
      timestamp: map['timestamp'] as DateTime? ?? DateTime.now(),
      isError: map['isError'] as bool? ?? false,
    );
  }

  final String text;
  final bool isCommand;
  final DateTime timestamp;
  final bool isError;

  /// Convert to Map for compatibility with existing widgets.
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isCommand': isCommand,
      'timestamp': timestamp,
      'isError': isError,
    };
  }
}
