import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../controllers/command_manager.dart';
import '../services/command_parameter_storage_service.dart';
import '../core/interfaces/command_repository_interface.dart';
import '../core/service_locator.dart' show getIt;
import '../core/view_model/view_model.dart';
import '../models/ble_device.dart';
import '../models/command/command.dart';
import '../models/command/custom_command.dart';
import '../models/connection_state.dart';
import '../models/device_info.dart';
import '../models/role/user_role.dart';
import '../services/command_log_service.dart';
import '../services/custom_command_service.dart';
import '../services/device_info_tracker.dart';
import '../services/role_service.dart';
import '../utils/logger.dart';
import '../widgets/message/message_filter_widget.dart';

// MessageData moved to command_log_service.dart when the chat log became an
// app-wide service (a service must not import a view_model). Re-exported so
// existing importers of this file keep compiling unchanged.
export '../services/command_log_service.dart' show MessageData;

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
    DeviceInfoTracker? deviceInfoTracker,
    CommandLogService? commandLog,
  })  : _injectedController = controller,
        _injectedCommandRepository = commandRepository,
        _injectedParameterStorageService = parameterStorageService,
        _injectedDeviceInfoTracker = deviceInfoTracker,
        _injectedCommandLog = commandLog;

  final BleControllerInterface? _injectedController;
  final CommandRepositoryInterface? _injectedCommandRepository;
  final CommandParameterStorageService? _injectedParameterStorageService;
  final DeviceInfoTracker? _injectedDeviceInfoTracker;
  final CommandLogService? _injectedCommandLog;
  late final BleControllerInterface _controller;
  late final CommandManager _commandManager;
  late final CommandRepositoryInterface _commandRepository;
  late final CommandParameterStorageService _parameterStorageService;
  late final DeviceInfoTracker _deviceInfoTracker;
  final ScrollController _scrollController = ScrollController();
  MessageFilter _currentFilter = MessageFilter.all;
  String? _executingCommand;
  bool _isAutoScrollPaused = false;
  int _unreadCount = 0;
  static const double _nearBottomThreshold = 50.0;

  // The chat log itself is NOT owned here. This VM dies with its route, so a
  // list held here is destroyed the moment the user navigates back to the
  // scanner while still connected. Resolved lazily rather than in onInit()
  // because several call sites reach the message API before initialize().
  CommandLogService? _resolvedCommandLog;
  CommandLogService get _commandLog =>
      _resolvedCommandLog ??= _injectedCommandLog ?? getIt<CommandLogService>();

  /// The shared [DeviceInfoTracker] that maintains the connected device's
  /// parsed [DeviceInfo]. Exposed so the View can hand its current snapshot
  /// to the Quick Setup Wizard without the VM holding a buffer of its own.
  DeviceInfoTracker get deviceInfoTracker => _deviceInfoTracker;

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

  /// Whether auto-scroll is paused (user scrolled up).
  bool get isAutoScrollPaused => _isAutoScrollPaused;

  /// Number of new messages since auto-scroll was paused.
  int get unreadCount => _unreadCount;

  /// Firmware name parsed from device $INFO response, or null when unknown.
  String? get firmwareName => _deviceInfoTracker.current.firmwareName;

  /// Structured device info parsed incrementally from $INFO responses.
  DeviceInfo get latestDeviceInfo => _deviceInfoTracker.current;

  /// Scroll controller for the message list.
  ScrollController get scrollController => _scrollController;

  /// List of messages (commands and responses).
  /// Lives in [CommandLogService] so it survives this VM being disposed with
  /// its route.
  List<MessageData> get messages => _commandLog.messages;

  /// Whether there are any messages.
  bool get hasMessages => _commandLog.messages.isNotEmpty;

  /// Number of messages.
  int get messageCount => _commandLog.messages.length;

  /// Current message filter.
  MessageFilter get currentFilter => _currentFilter;

  /// Filtered messages based on current filter.
  List<MessageData> get filteredMessages {
    final all = _commandLog.messages;
    switch (_currentFilter) {
      case MessageFilter.all:
        return all;
      case MessageFilter.commands:
        return List.unmodifiable(all.where((m) => m.isCommand).toList());
      case MessageFilter.responses:
        return List.unmodifiable(
            all.where((m) => !m.isCommand && !m.isError).toList());
      case MessageFilter.errors:
        return List.unmodifiable(all.where((m) => m.isError).toList());
    }
  }

  /// Get counts for each filter type.
  Map<MessageFilter, int> get messageCounts {
    final all = _commandLog.messages;
    return {
      MessageFilter.all: all.length,
      MessageFilter.commands: all.where((m) => m.isCommand).length,
      MessageFilter.responses:
          all.where((m) => !m.isCommand && !m.isError).length,
      MessageFilter.errors: all.where((m) => m.isError).length,
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
    _deviceInfoTracker =
        _injectedDeviceInfoTracker ?? getIt<DeviceInfoTracker>();

    // Initialize parameter storage
    await _parameterStorageService.initialize();

    // Add scroll listener for smart auto-scroll
    _scrollController.addListener(_onScrollPositionChanged);

    // Create command manager with callbacks
    _commandManager = CommandManager(
      controller: _controller,
      onCommandSent: _onUserCommandSent,
      onMessageAdded: _onMessageFromCommandManager,
    );

    // Initialize controller if needed
    await _ensureControllerInitialized();

    // Subscribe to the shared chat log rather than to the raw response
    // stream: CommandLogService owns that subscription, so response lines
    // arriving while this route is off-screen are still recorded.
    subscribe<CommandLogChange>(
      _commandLog.changeStream,
      _onLogChanged,
    );

    // Subscribe to the tracker so the firmware-name chip and any other
    // DeviceInfo-driven UI element rebuilds as soon as parsed values
    // change. The tracker itself does the parsing and accumulation.
    subscribe<DeviceInfo>(
      _deviceInfoTracker.infoStream,
      (_) => safeNotifyListeners(),
    );

    // Subscribe to role changes so the command list and input panel
    // re-render whenever the user enters or leaves developer mode.
    subscribe<UserRole>(
      getIt<RoleService>().roleStream,
      (_) => safeNotifyListeners(),
    );

    // Subscribe to custom-command changes so the command menu / quick
    // access bar reflect additions, edits, and deletions immediately
    // without waiting for a rebuild from another state change.
    subscribe<List<CustomCommand>>(
      getIt<CustomCommandService>().changeStream,
      (_) => safeNotifyListeners(),
    );

    // Auto-send $INFO on new connections so the FW chip appears without
    // the user needing to press the button manually.
    subscribe<BleDeviceModel?>(
      _controller.connectedDeviceStream,
      _onConnectionChanged,
    );

    // If a device is already connected when the view opens, try
    // auto-querying immediately.
    _autoSendInfoIfReady();
  }

  /// React to connection state changes and auto-query $INFO once the
  /// UART channel is set up after service discovery.
  void _onConnectionChanged(BleDeviceModel? device) {
    if (device != null && device.connectionState.isConnected) {
      // Service discovery + UART setup runs right after the connected
      // state is emitted, so wait a short beat for the command channel
      // to become available before sending.
      Future.delayed(const Duration(seconds: 2), _autoSendInfoIfReady);
    }
  }

  /// Send $INFO silently if we haven't already parsed a FW name and the
  /// command channel is available. Uses [sendPredefinedCommand] so both the
  /// command and the response appear in the chat log naturally.
  void _autoSendInfoIfReady() {
    if (_deviceInfoTracker.current.firmwareName != null) return;
    final info = _controller.getCommandInfo();
    if (info['hasCommandChannel'] != true) return;
    if (_controller.connectedDevice == null) return;
    _commandManager.sendPredefinedCommand(r'$INFO');
  }

  /// Whether the user is allowed to type commands manually.
  ///
  /// Manual input is reserved for developer mode — field operators in
  /// normal mode can only send the whitelisted commands via the menu.
  bool get canManualInput => getIt<RoleService>().currentRole.isDeveloper;

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

  void _onMessageFromCommandManager(Map<String, dynamic> messageMap) {
    addMessage(MessageData.fromMap(messageMap));
  }

  /// Add a message to the shared log. Scroll and unread bookkeeping happens in
  /// [_onLogChanged], which also covers messages the service appends itself
  /// (device response lines).
  void addMessage(MessageData message) {
    _commandLog.add(message);
  }

  /// Clear all messages. This is the clear_all button — the only user action
  /// that may destroy the log. Navigation must never reach here.
  void clearMessages() {
    _commandLog.clear();
    _isAutoScrollPaused = false;
    _unreadCount = 0;
    safeNotifyListeners();
  }

  void _onLogChanged(CommandLogChange change) {
    if (change == CommandLogChange.cleared) {
      _isAutoScrollPaused = false;
      _unreadCount = 0;
      safeNotifyListeners();
      return;
    }
    if (_isAutoScrollPaused) {
      _unreadCount++;
      safeNotifyListeners();
    } else {
      safeNotifyListeners();
      _scrollToBottom();
    }
  }

  /// Resume auto-scroll, clear unread count, and scroll to bottom.
  void resumeAutoScroll() {
    _isAutoScrollPaused = false;
    _unreadCount = 0;
    safeNotifyListeners();
    _scrollToBottom();
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

  void _onScrollPositionChanged() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final isNearBottom =
        position.pixels >= position.maxScrollExtent - _nearBottomThreshold;

    if (isNearBottom && _isAutoScrollPaused) {
      _isAutoScrollPaused = false;
      _unreadCount = 0;
      safeNotifyListeners();
    } else if (!isNearBottom && !_isAutoScrollPaused) {
      _isAutoScrollPaused = true;
      safeNotifyListeners();
    }
  }

  void _onUserCommandSent() {
    _isAutoScrollPaused = false;
    _unreadCount = 0;
    safeNotifyListeners();
    _scrollToBottom();
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
    // NOTE: _commandLog is a locator singleton and is deliberately NOT
    // disposed or cleared here — doing so is exactly the bug this VM used to
    // have, where the log died with the route while the BLE link stayed up.
    _commandManager.dispose();
    _scrollController.removeListener(_onScrollPositionChanged);
    _scrollController.dispose();
    super.onDispose();
  }
}
