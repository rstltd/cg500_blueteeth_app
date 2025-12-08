import 'dart:async';
import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../controllers/command_manager.dart';
import '../models/ble_device.dart';
import '../services/notification_service.dart'; // For NotificationModel and NotificationType
import '../services/theme_service.dart';
import '../core/service_locator.dart' show getIt;
import '../core/mixins/notification_listener_mixin.dart';
import '../utils/logger.dart';
import '../utils/responsive_utils.dart';
import '../utils/formatting_utils.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/message_bubble_widget.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/device_status_panel_widget.dart';
import '../widgets/command_input_panel_widget.dart';
import '../widgets/command_history_panel_widget.dart';

/// Command Interface View for sending text commands to BLE devices
/// and receiving responses in real-time.
///
/// Supports dependency injection for testability:
/// - Use default constructor for production (uses service locator)
/// - Use [CommandInterfaceView.withDependencies] for testing
class CommandInterfaceView extends StatefulWidget {
  /// Creates a CommandInterfaceView using the service locator for dependencies.
  const CommandInterfaceView({super.key}) : _controller = null;

  /// Creates a CommandInterfaceView with explicit dependencies for testing.
  const CommandInterfaceView.withDependencies({
    super.key,
    required BleControllerInterface controller,
  }) : _controller = controller;

  final BleControllerInterface? _controller;

  @override
  State<CommandInterfaceView> createState() => _CommandInterfaceViewState();
}

class _CommandInterfaceViewState extends State<CommandInterfaceView>
    with NotificationListenerMixin<CommandInterfaceView> {
  late final BleControllerInterface _controller;
  final ScrollController _responseScrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  late CommandManager _commandManager;
  bool _isInitialized = false;

  // StreamSubscription for command responses
  StreamSubscription<String>? _responseSubscription;

  @override
  Stream<NotificationModel> get notificationStream =>
      _controller.notificationStream;

  @override
  void initState() {
    super.initState();
    // Use injected dependency or fall back to service locator
    _controller = widget._controller ?? getIt<BleControllerInterface>();
    _commandManager = CommandManager(
      controller: _controller,
      onCommandSent: _scrollToBottom,
      onMessageAdded: _addMessage,
    );
    _initializeController();
    _listenToResponses();
    initializeNotificationListener();
  }

  Future<void> _initializeController() async {
    // The controller should already be initialized from the main scanner page
    // But let's ensure it's ready
    if (!_controller.isInitialized) {
      bool success = await _controller.initialize();
      setState(() {
        _isInitialized = success;
      });
      Logger.ui('Controller initialized = $success');
    } else {
      setState(() {
        _isInitialized = true;
      });
      Logger.ui('Controller already initialized');
    }

    // Check connection status for UI initialization
    final connectedDevice = _controller.connectedDevice;
    if (connectedDevice != null) {
      Logger.ui('Connected to: ${connectedDevice.displayName}');
    }

    // Wait a moment to ensure all state updates are processed
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    // Cancel response subscription
    _responseSubscription?.cancel();
    disposeNotificationListener();
    _commandManager.dispose();
    _responseScrollController.dispose();
    super.dispose();
  }

  void _listenToResponses() {
    _responseSubscription = _controller.commandResponseStream.listen((response) {
      if (mounted) {
        _addMessage({
          'text': response,
          'isCommand': false,
          'timestamp': DateTime.now(),
        });
      }
    });
  }

  void _addMessage(Map<String, dynamic> message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_responseScrollController.hasClients) {
        _responseScrollController.animateTo(
          _responseScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendCommand() async {
    await _commandManager.sendCommand();
  }

  void _navigateHistory(bool up) {
    if (up) {
      _commandManager.historyUp();
    } else {
      _commandManager.historyDown();
    }
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Command Interface'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing command interface...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: ConnectionStatusAppBar(
        controller: _controller,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => setState(() => _messages.clear()),
            tooltip: 'Clear Messages',
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(), 
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildStatusPanel() {
    return DeviceStatusPanelWidget(controller: _controller);
  }

  Widget _buildResponseArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Communication',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _clearMessages,
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear Messages',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: MessageListWidget(
                messages: _messages,
                scrollController: _responseScrollController,
                autoScroll: true,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCommandInput() {
    return CommandInputPanelWidget(
      controller: _controller,
      commandManager: _commandManager,
      onSendCommand: _sendCommand,
      onNavigateHistory: _navigateHistory,
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Connection Status & Info Panel
        _buildStatusPanel(),
        
        // Response Display Area
        Expanded(
          child: _buildResponseArea(),
        ),
        
        // Command Input Area
        _buildCommandInput(),
      ],
    );
  }

  // Tablet Layout
  Widget _buildTabletLayout() {
    return ResponsiveUtils.isLandscape(context)
        ? _buildTabletLandscapeLayout()
        : _buildTabletPortraitLayout();
  }

  Widget _buildTabletPortraitLayout() {
    return ResponsiveContainer(
      child: Column(
        children: [
          // Connection Status & Info Panel
          _buildStatusPanel(),
          
          // Response Display Area with max width
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getCardMaxWidth(context) * 2,
                ),
                child: _buildResponseArea(),
              ),
            ),
          ),
          
          // Command Input Area
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.getCardMaxWidth(context) * 2,
              ),
              child: _buildCommandInput(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLandscapeLayout() {
    return ResponsiveContainer(
      child: Row(
        children: [
          // Left Panel - Device Status and Command History
          SizedBox(
            width: 300,
            child: Column(
              children: [
                _buildStatusPanel(),
                const SizedBox(height: 16),
                _buildCommandHistoryPanel(),
              ],
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            color: AppColors.borderColor(context),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          
          // Right Panel - Chat Area and Input
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildResponseArea(),
                ),
                _buildCommandInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Layout
  Widget _buildDesktopLayout() {
    return ResponsiveContainer(
      child: Row(
        children: [
          // Left Sidebar - Device Info and Stats
          SizedBox(
            width: 350,
            child: Column(
              children: [
                _buildStatusPanel(),
                const SizedBox(height: 16),
                _buildCommandHistoryPanel(),
                const SizedBox(height: 16),
                _buildConnectionStatsPanel(),
              ],
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            color: AppColors.borderColor(context),
            margin: const EdgeInsets.symmetric(horizontal: 24),
          ),
          
          // Main Chat Area
          Expanded(
            child: Column(
              children: [
                // Chat Header
                Container(
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  child: Row(
                    children: [
                      ResponsiveText(
                        'Device Communication',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _clearMessages,
                        icon: const Icon(Icons.clear_all),
                        tooltip: 'Clear Messages',
                      ),
                    ],
                  ),
                ),
                
                // Chat Messages
                Expanded(
                  child: _buildResponseArea(),
                ),
                
                // Command Input
                _buildCommandInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Command History Panel for larger screens
  Widget _buildCommandHistoryPanel() {
    return CommandHistoryPanelWidget(commandManager: _commandManager);
  }

  // Connection Stats Panel for desktop
  Widget _buildConnectionStatsPanel() {
    return StreamBuilder<BleDeviceModel?>(
      stream: _controller.connectedDeviceStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final device = snapshot.data!;
        Map<String, dynamic> commandInfo = _controller.getCommandInfo();

        return ResponsiveCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                'Connection Stats',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary(context),
              ),
              const SizedBox(height: 16),
              _buildStatRow('Device Name', device.displayName),
              _buildStatRow('Signal Strength', '${device.rssi} dBm'),
              _buildStatRow('Services', '${device.services.length}'),
              _buildStatRow('MTU Size', '${commandInfo['mtu']} bytes'),
              _buildStatRow('Messages Sent', '${_commandManager.commandHistory.length}'),
              if (device.connectionDuration != null)
                _buildStatRow('Connected For', _formatDuration(device.connectionDuration!)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ResponsiveText(
              label,
              fontSize: 12,
              color: AppColors.textSecondary(context),
            ),
          ),
          ResponsiveText(
            value,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    return FormattingUtils.formatDuration(duration);
  }
}