import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../controllers/app_update_manager.dart';
import '../core/view_model/view_model.dart';
import '../design/design_system.dart';
import '../models/ble_device.dart';
import '../services/animation_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../utils/formatting_utils.dart';
import '../view_models/simple_scanner_view_model.dart';
import '../widgets/device_list_widget.dart';
import '../widgets/notification_settings_dialog.dart';
import '../widgets/update_notification_banner.dart';
import '../widgets/control_panel_widget.dart';
import '../widgets/scanning_indicator_widget.dart';
import '../widgets/connected_device_card_widget.dart';
import '../widgets/quick_stats_widget.dart';
import '../widgets/device_grid_widget.dart';
import '../widgets/device_details_dialog.dart';
import '../widgets/device_search_widget.dart';
import 'command_interface_view.dart';
import 'update_settings_view.dart';

/// Simple Scanner View using ViewModelProvider pattern.
///
/// Uses the ViewModelProvider pattern for better separation of concerns.
///
/// Key features:
/// - State management via SimpleScannerViewModel
/// - Automatic subscription lifecycle management
/// - Clean, testable code structure
class SimpleScannerView extends StatelessWidget {
  /// Creates a SimpleScannerView using the service locator.
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
  Widget build(BuildContext context) {
    return ViewModelProvider<SimpleScannerViewModel>(
      create: () => SimpleScannerViewModel(
        controller: _controller,
        themeService: _themeService,
        updateManager: _updateManager,
      ),
      builder: (context, viewModel, child) {
        return _SimpleScannerContent(viewModel: viewModel);
      },
    );
  }
}

/// The main content widget that uses the ViewModel.
class _SimpleScannerContent extends StatefulWidget {
  const _SimpleScannerContent({required this.viewModel});

  final SimpleScannerViewModel viewModel;

  @override
  State<_SimpleScannerContent> createState() => _SimpleScannerContentState();
}

class _SimpleScannerContentState extends State<_SimpleScannerContent> {
  SimpleScannerViewModel get viewModel => widget.viewModel;

  @override
  void initState() {
    super.initState();
    // Subscribe to notifications for SnackBar display
    viewModel.notificationStream.listen(_handleNotification);
  }

  void _handleNotification(NotificationModel notification) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${notification.title}: ${notification.message}'),
          backgroundColor: FormattingUtils.getNotificationColor(notification.type),
          duration: notification.duration ?? const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (!viewModel.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('CG500 BLE Scanner'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: DesignTokens.spacingML),
              const Text('Initializing BLE Controller...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Update notification banner
          UpdateNotificationBanner(
            updateManager: viewModel.updateManager,
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

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('CG500 BLE Scanner'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        // Search Button
        DeviceSearchWidget(
          onSearchChanged: viewModel.setSearchQuery,
          onSearchClosed: viewModel.clearSearch,
        ),

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
        _buildSettingsMenu(context),

        // Connected Device Actions
        _buildConnectedDeviceActions(context),
      ],
    );
  }

  Widget _buildSettingsMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'More Settings',
      onSelected: (String value) {
        switch (value) {
          case 'check_updates':
            viewModel.checkForUpdates(force: true);
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
            viewModel.toggleTheme();
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'check_updates',
          child: Row(
            children: [
              const Icon(Icons.refresh),
              SizedBox(width: DesignTokens.spacingSM),
              const Text('Check for Updates'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'update_settings',
          child: Row(
            children: [
              const Icon(Icons.system_update_alt),
              SizedBox(width: DesignTokens.spacingSM),
              const Text('Update Settings'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'toggle_theme',
          child: StreamBuilder<AppThemeMode>(
            stream: viewModel.themeModeStream,
            initialData: viewModel.themeMode,
            builder: (context, snapshot) {
              return Row(
                children: [
                  Icon(viewModel.themeModeIcon),
                  SizedBox(width: DesignTokens.spacingSM),
                  Text(viewModel.themeModeDescription),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedDeviceActions(BuildContext context) {
    return StreamBuilder<BleDeviceModel?>(
      stream: viewModel.connectedDeviceStream,
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
    );
  }

  // --- Layout Builders ---

  Widget _buildControlPanel() {
    return ControlPanelWidget(controller: viewModel.controller);
  }

  Widget _buildScanningIndicator() {
    return ScanningIndicatorWidget(controller: viewModel.controller);
  }

  Widget _buildDeviceList() {
    return DeviceListWidget(
      controller: viewModel.controller,
      onDeviceConnect: (device) => viewModel.connectToDevice(device.id),
      onDeviceDisconnect: (device) => viewModel.disconnectDevice(),
      onDeviceFavorite: (device) => _toggleDeviceFavorite(device),
      searchQuery: viewModel.searchQuery,
    );
  }

  void _toggleDeviceFavorite(BleDeviceModel device) {
    final updatedDevice = viewModel.toggleDeviceFavorite(device);
    debugPrint('Device ${device.id} favorite toggled: ${updatedDevice.isFavorite}');
  }

  void _showDeviceDetails(BleDeviceModel device) {
    DeviceDetailsDialog.show(context, device);
  }

  void _showConnectedDeviceInfo(BleDeviceModel device) {
    DeviceDetailsDialog.show(context, device);
  }

  // Mobile Layout
  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildControlPanel(),
        _buildScanningIndicator(),
        Expanded(child: _buildDeviceList()),
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
          _buildControlPanel(),
          _buildScanningIndicator(),
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
    final sidebarWidth = ResponsiveUtils.getTabletSidebarWidth(context);

    return Row(
      children: [
        // Left Panel - optimized width based on tablet size
        Container(
          width: sidebarWidth,
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            children: [
              _buildControlPanel(),
              _buildScanningIndicator(),
              SizedBox(height: ResponsiveUtils.getTabletItemGap(context)),
              StreamBuilder<BleDeviceModel?>(
                stream: viewModel.connectedDeviceStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return _buildConnectedDeviceCard(snapshot.data!);
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Show quick stats on larger tablets
              if (ResponsiveUtils.isTabletLarge(context)) ...[
                SizedBox(height: DesignTokens.spacingM),
                _buildQuickStats(),
              ],
            ],
          ),
        ),
        Container(
          width: DesignTokens.dividerThickness,
          color: AppColors.borderColor(context),
        ),
        Expanded(
          child: _buildDeviceList(),
        ),
      ],
    );
  }

  // Desktop Layout
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
                SizedBox(height: DesignTokens.spacingML),
                StreamBuilder<BleDeviceModel?>(
                  stream: viewModel.connectedDeviceStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return _buildConnectedDeviceCard(snapshot.data!);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                SizedBox(height: DesignTokens.spacingM),
                _buildQuickStats(),
              ],
            ),
          ),
          Container(
            width: 1,
            color: AppColors.borderColor(context),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: DesignTokens.paddingM,
                  child: Row(
                    children: [
                      ResponsiveText(
                        'Available Devices',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
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

  Widget _buildConnectedDeviceCard(BleDeviceModel device) {
    return ConnectedDeviceCardWidget(device: device);
  }

  Widget _buildQuickStats() {
    return QuickStatsWidget(controller: viewModel.controller);
  }

  Widget _buildResponsiveDeviceGrid() {
    return DeviceGridWidget(
      controller: viewModel.controller,
      onDeviceDetails: _showDeviceDetails,
    );
  }
}
