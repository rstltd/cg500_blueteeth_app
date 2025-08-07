import 'package:flutter/material.dart';
import '../controllers/simple_ble_controller.dart';
import '../models/ble_device.dart';
import '../models/connection_state.dart';
import '../services/animation_service.dart';
import '../services/notification_service.dart'; // For NotificationModel and NotificationType
import '../services/theme_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/device_list_widget.dart';
import '../widgets/notification_settings_dialog.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/update_notification_banner.dart';
import '../controllers/app_update_manager.dart';
import '../widgets/control_panel_widget.dart';
import '../widgets/scanning_indicator_widget.dart';
import '../widgets/connected_device_card_widget.dart';
import '../widgets/quick_stats_widget.dart';
import '../widgets/device_grid_widget.dart';
import 'command_interface_view.dart';
import 'update_settings_view.dart';

/// Simple Scanner View demonstrating MVC architecture usage
/// Shows how Views interact with Controllers instead of directly with Services
class SimpleScannerView extends StatefulWidget {
  const SimpleScannerView({super.key});

  @override
  State<SimpleScannerView> createState() => _SimpleScannerViewState();
}

class _SimpleScannerViewState extends State<SimpleScannerView> {
  final SimpleBleController _controller = SimpleBleController();
  final ThemeService _themeService = ThemeService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeController() async {
    bool success = await _controller.initialize();
    setState(() {
      _isInitialized = success;
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

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('CG500 BLE Scanner'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Initializing BLE Controller...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CG500 BLE Scanner v2.0.15'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Notification Settings Button
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const NotificationSettingsDialog(),
            ),
            tooltip: 'Notification Settings',
          ),
          
          // More Settings Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Settings',
            onSelected: (String value) {
              switch (value) {
                case 'check_updates':
                  AppUpdateManager().checkForUpdatesWithUI(force: true);
                  break;
                case 'update_settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UpdateSettingsView(),
                    ),
                  );
                  break;
                case 'toggle_theme':
                  _themeService.toggleTheme();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'check_updates',
                child: Row(
                  children: [
                    const Icon(Icons.refresh),
                    const SizedBox(width: 12),
                    const Text('Check for Updates'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'update_settings',
                child: Row(
                  children: [
                    const Icon(Icons.system_update_alt),
                    const SizedBox(width: 12),
                    const Text('Update Settings'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'toggle_theme',
                child: StreamBuilder<AppThemeMode>(
                  stream: _themeService.themeModeStream,
                  initialData: _themeService.currentThemeMode,
                  builder: (context, snapshot) {
                    return Row(
                      children: [
                        Icon(_themeService.themeModeIcon),
                        const SizedBox(width: 12),
                        Text(_themeService.themeModeDescription),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Connected Device Actions
          StreamBuilder<BleDeviceModel?>(
            stream: _controller.connectedDeviceStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat),
                      onPressed: () => Navigator.of(context).push(
                        AnimationService.createPageTransition(
                          page: const CommandInterfaceView(),
                          type: PageTransitionType.slideFromBottom,
                        ),
                      ),
                      tooltip: 'Command Interface',
                    ),
                    IconButton(
                      icon: const Icon(Icons.bluetooth_connected),
                      onPressed: () => _showConnectedDeviceInfo(snapshot.data!),
                      tooltip: 'Device Info',
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Update notification banner (replaces legacy banner)
          UpdateNotificationBanner(
            updateManager: AppUpdateManager(),
          ),
          
          // Main content
          Expanded(
            child: ResponsiveLayout(
              mobile: _buildMobileLayout(),
              tablet: _buildTabletLayout(),
              desktop: _buildDesktopLayout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return ControlPanelWidget(controller: _controller);
  }

  Widget _buildScanningIndicator() {
    return ScanningIndicatorWidget(controller: _controller);
  }

  Widget _buildDeviceList() {
    return DeviceListWidget(
      controller: _controller,
      onDeviceConnect: (device) => _controller.connectToDevice(device.id),
      onDeviceDisconnect: (device) => _controller.disconnectDevice(),
      onDeviceFavorite: (device) => _toggleDeviceFavorite(device),
    );
  }

  /// Toggle device favorite status
  void _toggleDeviceFavorite(BleDeviceModel device) {
    // Use the built-in toggleFavorite method from the model
    // In a real app, this might save to persistent storage via controller
    final updatedDevice = device.toggleFavorite();
    // Notify controller of the change (assuming controller has such a method)
    // For now, this is a placeholder as we need to update the controller
    debugPrint('Device ${device.id} favorite toggled: ${updatedDevice.isFavorite}');
  }



  void _showDeviceDetails(BleDeviceModel device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(device.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Device ID', device.id),
              _buildInfoRow('Name', device.name.isNotEmpty ? device.name : 'Unknown'),
              _buildInfoRow('RSSI', '${device.rssi} dBm (${device.rssiDescription})'),
              _buildInfoRow('Connection', device.connectionState.displayName),
              if (device.lastSeen != null)
                _buildInfoRow('Last Seen', _formatDateTime(device.lastSeen!)),
              if (device.connectedAt != null)
                _buildInfoRow('Connected At', _formatDateTime(device.connectedAt!)),
              if (device.connectionDuration != null)
                _buildInfoRow('Duration', _formatDuration(device.connectionDuration!)),
              _buildInfoRow('Services', '${device.services.length}'),
              if (device.services.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...device.services.map((service) => 
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• ${service.displayName}'),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showConnectedDeviceInfo(BleDeviceModel device) {
    _showDeviceDetails(device);
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  // Mobile Layout (Portrait and small screens)
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Control Panel
        _buildControlPanel(),
        
        // Scanning Indicator
        _buildScanningIndicator(),
        
        // Device List
        Expanded(child: _buildDeviceList()),
      ],
    );
  }

  // Tablet Layout (Medium screens)
  Widget _buildTabletLayout() {
    return ResponsiveUtils.isLandscape(context)
        ? _buildTabletLandscapeLayout()
        : _buildTabletPortraitLayout();
  }

  Widget _buildTabletPortraitLayout() {
    return ResponsiveContainer(
      child: Column(
        children: [
          // Control Panel
          _buildControlPanel(),
          
          // Scanning Indicator
          _buildScanningIndicator(),
          
          // Device List with responsive card width
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getCardMaxWidth(context) * 1.5,
                ),
                child: _buildDeviceList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLandscapeLayout() {
    return Row(
      children: [
        // Left Panel - Control and Connected Device Info
        Container(
          width: 320,
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            children: [
              _buildControlPanel(),
              _buildScanningIndicator(),
              const SizedBox(height: 16),
              // Connected device quick info
              StreamBuilder<BleDeviceModel?>(
                stream: _controller.connectedDeviceStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _buildConnectedDeviceCard(snapshot.data!);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        
        // Divider
        Container(
          width: 1,
          color: AppColors.borderColor(context),
        ),
        
        // Right Panel - Device List
        Expanded(
          child: _buildDeviceList(),
        ),
      ],
    );
  }

  // Desktop Layout (Large screens)
  Widget _buildDesktopLayout() {
    return ResponsiveContainer(
      child: Row(
        children: [
          // Left Sidebar
          Container(
            width: 380,
            padding: ResponsiveUtils.getResponsivePadding(context),
            child: Column(
              children: [
                _buildControlPanel(),
                _buildScanningIndicator(),
                const SizedBox(height: 20),
                
                // Connected device detailed info
                StreamBuilder<BleDeviceModel?>(
                  stream: _controller.connectedDeviceStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildConnectedDeviceCard(snapshot.data!);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                // Quick stats
                const SizedBox(height: 16),
                _buildQuickStats(),
              ],
            ),
          ),
          
          // Divider
          Container(
            width: 1,
            color: AppColors.borderColor(context),
          ),
          
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Header with search functionality (future enhancement)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ResponsiveText(
                        'Available Devices',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                      const Spacer(),
                      // Future: Add search and filter buttons here
                    ],
                  ),
                ),
                
                // Device grid for desktop
                Expanded(
                  child: _buildResponsiveDeviceGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Connected device card for sidebar
  Widget _buildConnectedDeviceCard(BleDeviceModel device) {
    return ConnectedDeviceCardWidget(device: device);
  }

  // Quick stats widget
  Widget _buildQuickStats() {
    return QuickStatsWidget(controller: _controller);
  }

  // Responsive device grid for larger screens
  Widget _buildResponsiveDeviceGrid() {
    return DeviceGridWidget(
      controller: _controller,
      onDeviceDetails: _showDeviceDetails,
    );
  }
}