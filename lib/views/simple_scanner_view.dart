import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../controllers/app_update_manager.dart';
import '../models/ble_device.dart';
import '../services/animation_service.dart';
import '../services/notification_service.dart'; // For NotificationModel and NotificationType
import '../services/theme_service.dart';
import '../core/service_locator.dart';
import '../core/mixins/notification_listener_mixin.dart';
import '../utils/responsive_utils.dart';
import '../widgets/device_list_widget.dart';
import '../widgets/notification_settings_dialog.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/update_notification_banner.dart';
import '../widgets/control_panel_widget.dart';
import '../widgets/scanning_indicator_widget.dart';
import '../widgets/connected_device_card_widget.dart';
import '../widgets/quick_stats_widget.dart';
import '../widgets/device_grid_widget.dart';
import '../widgets/device_details_dialog.dart';
import 'command_interface_view.dart';
import 'update_settings_view.dart';

/// Simple Scanner View demonstrating MVC architecture usage.
/// Shows how Views interact with Controllers instead of directly with Services.
///
/// Supports dependency injection for testability:
/// - Use default constructor for production (uses service locator)
/// - Use [SimpleScannerView.withDependencies] for testing
class SimpleScannerView extends StatefulWidget {
  /// Creates a SimpleScannerView using the service locator for dependencies.
  const SimpleScannerView({super.key})
      : _controller = null,
        _themeService = null,
        _updateManager = null;

  /// Creates a SimpleScannerView with explicit dependencies for testing.
  const SimpleScannerView.withDependencies({
    super.key,
    required BleControllerInterface controller,
    required ThemeService themeService,
    required AppUpdateManager updateManager,
  })  : _controller = controller,
        _themeService = themeService,
        _updateManager = updateManager;

  final BleControllerInterface? _controller;
  final ThemeService? _themeService;
  final AppUpdateManager? _updateManager;

  @override
  State<SimpleScannerView> createState() => _SimpleScannerViewState();
}

class _SimpleScannerViewState extends State<SimpleScannerView>
    with NotificationListenerMixin<SimpleScannerView> {
  late final BleControllerInterface _controller;
  late final ThemeService _themeService;
  late final AppUpdateManager _updateManager;
  bool _isInitialized = false;

  @override
  Stream<NotificationModel> get notificationStream =>
      _controller.notificationStream;

  @override
  void initState() {
    super.initState();
    // Use injected dependencies or fall back to service locator
    _controller = widget._controller ?? getIt<BleControllerInterface>();
    _themeService = widget._themeService ?? getIt<ThemeService>();
    _updateManager = widget._updateManager ?? getIt<AppUpdateManager>();
    _initializeController();
    initializeNotificationListener();
  }

  @override
  void dispose() {
    disposeNotificationListener();
    // Note: Don't dispose controller as it's managed by service locator
    super.dispose();
  }

  Future<void> _initializeController() async {
    bool success = await _controller.initialize();
    setState(() {
      _isInitialized = success;
    });
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
        title: const Text('CG500 BLE Scanner'),
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
                  _updateManager.checkForUpdatesWithUI(force: true);
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
            updateManager: _updateManager,
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
    DeviceDetailsDialog.show(context, device);
  }

  void _showConnectedDeviceInfo(BleDeviceModel device) {
    DeviceDetailsDialog.show(context, device);
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