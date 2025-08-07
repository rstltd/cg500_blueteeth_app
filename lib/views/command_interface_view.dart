import 'package:flutter/material.dart';
import '../controllers/simple_ble_controller.dart';
import '../controllers/command_manager.dart';
import '../models/ble_device.dart';
import '../services/notification_service.dart'; // For NotificationModel and NotificationType
import '../services/theme_service.dart';
import '../utils/logger.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/message_bubble_widget.dart';
import '../widgets/connection_status_widget.dart';

/// Command Interface View for sending text commands to BLE devices
/// and receiving responses in real-time
class CommandInterfaceView extends StatefulWidget {
  const CommandInterfaceView({super.key});

  @override
  State<CommandInterfaceView> createState() => _CommandInterfaceViewState();
}

class _CommandInterfaceViewState extends State<CommandInterfaceView> {
  final SimpleBleController _controller = SimpleBleController();
  final ScrollController _responseScrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  late CommandManager _commandManager;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _commandManager = CommandManager(
      controller: _controller,
      onCommandSent: _scrollToBottom,
      onMessageAdded: _addMessage,
    );
    _initializeController();
    _listenToResponses();
    _listenToNotifications();
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
    _commandManager.dispose();
    _responseScrollController.dispose();
    super.dispose();
  }

  void _listenToResponses() {
    _controller.commandResponseStream.listen((response) {
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

  void _listenToNotifications() {
    _controller.notificationStream.listen((notification) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification.title}: ${notification.message}'),
            backgroundColor: _getNotificationColor(notification.type),
            duration: notification.duration ?? const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.info:
        return Colors.blue;
    }
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
    return Container(
      margin: const EdgeInsets.all(16),
      child: StreamBuilder<BleDeviceModel?>(
        stream: _controller.connectedDeviceStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            final currentDevice = _controller.connectedDevice;
            
            if (currentDevice != null) {
              return _buildDeviceStatusPanel(currentDevice);
            }
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Device Connected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Please connect a BLE device first',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return _buildDeviceStatusPanel(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildDeviceStatusPanel(BleDeviceModel device) {
    Map<String, dynamic> commandInfo = _controller.getCommandInfo();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.backgroundGradientStart(context),
            AppColors.backgroundGradientEnd(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue.shade800.withValues(alpha: 0.3)
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.device_hub,
                  color: AppColors.infoColor(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      device.id,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatusChip(
                'TX',
                commandInfo['hasCommandChannel'] ?? false,
                Icons.upload,
              ),
              const SizedBox(width: 6),
              _buildStatusChip(
                'RX',
                commandInfo['hasResponseChannel'] ?? false,
                Icons.download,
              ),
              const SizedBox(width: 6),
              _buildInfoChip(
                'MTU',
                '${commandInfo['mtu']}',
                Icons.data_usage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, bool isAvailable, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAvailable ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: Colors.blue.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            '$label:$value',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
        stream: _controller.connectedDeviceStream,
        builder: (context, snapshot) {
          bool isConnected = snapshot.hasData || _controller.connectedDevice != null;
          Map<String, dynamic> commandInfo = _controller.getCommandInfo();
          bool canSendCommands = isConnected && (commandInfo['hasCommandChannel'] ?? false);

          return Column(
            children: [
              // Command Input Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: canSendCommands 
                              ? Colors.blue.shade200 
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _commandManager.textController,
                        enabled: canSendCommands,
                        decoration: InputDecoration(
                          hintText: canSendCommands 
                              ? 'Type your command...'
                              : 'Connect device to send commands',
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
                            color: canSendCommands 
                                ? Colors.blue.shade600 
                                : Colors.grey.shade400,
                          ),
                        ),
                        onSubmitted: canSendCommands ? (_) => _sendCommand() : null,
                        onChanged: (value) {
                          // Reset history navigation when user types
                        },
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send Button
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: canSendCommands 
                          ? Colors.blue.shade500 
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: canSendCommands ? [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: IconButton(
                      onPressed: canSendCommands ? _sendCommand : null,
                      icon: Icon(
                        Icons.send_rounded,
                        color: canSendCommands ? Colors.white : Colors.grey.shade500,
                      ),
                      iconSize: 24,
                    ),
                  ),
                ],
              ),
              
              // History Navigation
              if (_commandManager.commandHistory.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up),
                            onPressed: canSendCommands ? () => _navigateHistory(true) : null,
                            tooltip: 'Previous command',
                            iconSize: 20,
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down),
                            onPressed: canSendCommands ? () => _navigateHistory(false) : null,
                            tooltip: 'Next command',
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.history,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_commandManager.commandHistory.length} commands',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (canSendCommands)
                      Container(
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
                              'Ready',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
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
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: _commandManager.commandHistory.isEmpty
                ? Center(
                    child: ResponsiveText(
                      'No commands yet',
                      fontSize: 14,
                      color: AppColors.textSecondary(context),
                    ),
                  )
                : ListView.builder(
                    itemCount: _commandManager.commandHistory.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final reversedIndex = _commandManager.commandHistory.length - 1 - index;
                      final command = _commandManager.commandHistory[reversedIndex];
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
                              onPressed: () {
                                _commandManager.textController.text = command;
                              },
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
                    },
                  ),
          ),
        ],
      ),
    );
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
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}