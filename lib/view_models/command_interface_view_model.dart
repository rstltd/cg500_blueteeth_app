import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../controllers/command_manager.dart';
import '../services/command_parameter_storage_service.dart';
import '../core/interfaces/command_repository_interface.dart';
import '../core/service_locator.dart' show getIt;
import '../core/view_model/view_model.dart';
import '../models/command/command.dart';
import '../utils/logger.dart';
import '../widgets/message_filter_widget.dart';

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
  /// All parameters are optional for dependency injection (testing).
  /// If null, dependencies are retrieved from the service locator.
  CommandInterfaceViewModel({
    BleControllerInterface? controller,
    CommandRepositoryInterface? commandRepository,
    CommandParameterStorageService? parameterStorageService,
  })  : _injectedController = controller,
        _injectedCommandRepository = commandRepository,
        _injectedParameterStorageService = parameterStorageService;

  final BleControllerInterface? _injectedController;
  final CommandRepositoryInterface? _injectedCommandRepository;
  final CommandParameterStorageService? _injectedParameterStorageService;
  late final BleControllerInterface _controller;
  late final CommandManager _commandManager;
  late final CommandRepositoryInterface _commandRepository;
  late final CommandParameterStorageService _parameterStorageService;
  final ScrollController _scrollController = ScrollController();
  final List<MessageData> _messages = [];
  MessageFilter _currentFilter = MessageFilter.all;
  String? _executingCommand;

  /// The BLE controller instance.
  BleControllerInterface get controller => _controller;

  /// The command manager for sending commands.
  CommandManager get commandManager => _commandManager;

  /// The command repository for available commands.
  CommandRepositoryInterface get commandRepository => _commandRepository;

  /// The parameter storage service for persisting command parameters.
  CommandParameterStorageService get parameterStorageService =>
      _parameterStorageService;

  /// The currently executing command (for loading state).
  String? get executingCommand => _executingCommand;

  /// Scroll controller for the message list.
  ScrollController get scrollController => _scrollController;

  /// List of messages (commands and responses).
  List<MessageData> get messages => List.unmodifiable(_messages);

  /// Whether there are any messages.
  bool get hasMessages => _messages.isNotEmpty;

  /// Number of messages.
  int get messageCount => _messages.length;

  /// Current message filter.
  MessageFilter get currentFilter => _currentFilter;

  /// Filtered messages based on current filter.
  List<MessageData> get filteredMessages {
    switch (_currentFilter) {
      case MessageFilter.all:
        return List.unmodifiable(_messages);
      case MessageFilter.commands:
        return List.unmodifiable(
            _messages.where((m) => m.isCommand).toList());
      case MessageFilter.responses:
        return List.unmodifiable(
            _messages.where((m) => !m.isCommand && !m.isError).toList());
      case MessageFilter.errors:
        return List.unmodifiable(_messages.where((m) => m.isError).toList());
    }
  }

  /// Get counts for each filter type.
  Map<MessageFilter, int> get messageCounts {
    return {
      MessageFilter.all: _messages.length,
      MessageFilter.commands: _messages.where((m) => m.isCommand).length,
      MessageFilter.responses:
          _messages.where((m) => !m.isCommand && !m.isError).length,
      MessageFilter.errors: _messages.where((m) => m.isError).length,
    };
  }

  /// Set the current filter.
  void setFilter(MessageFilter filter) {
    if (_currentFilter != filter) {
      _currentFilter = filter;
      safeNotifyListeners();
    }
  }

  @override
  Future<void> onInit() async {
    // Use injected dependencies or get from service locator
    _controller = _injectedController ?? getIt<BleControllerInterface>();
    _commandRepository =
        _injectedCommandRepository ?? getIt<CommandRepositoryInterface>();
    _parameterStorageService = _injectedParameterStorageService ??
        getIt<CommandParameterStorageService>();

    // Initialize parameter storage
    await _parameterStorageService.initialize();

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

  /// Send the current command or a specific command text.
  ///
  /// Returns `true` if the command was sent successfully, `false` otherwise.
  Future<bool> sendCommand([String? commandText]) async {
    return _commandManager.sendCommand(commandText);
  }

  /// Execute a quick command from the quick access bar.
  ///
  /// Sets the executing command state for loading indication,
  /// sends the command, and clears the state after completion.
  ///
  /// Returns `true` if the command was sent successfully, `false` otherwise.
  Future<bool> executeQuickCommand(DeviceCommand command) async {
    if (_executingCommand != null) {
      // Already executing a command
      return false;
    }

    _executingCommand = command.command;
    safeNotifyListeners();

    try {
      // Add command to message log
      addMessage(MessageData(
        text: command.command,
        isCommand: true,
        timestamp: DateTime.now(),
      ));

      // Send via controller
      return await _controller.sendCommand(command.command);
    } finally {
      _executingCommand = null;
      safeNotifyListeners();
    }
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
