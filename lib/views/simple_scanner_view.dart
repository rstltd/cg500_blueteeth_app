import 'dart:async';

import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../controllers/app_update_manager.dart';
import '../core/mixins/notification_listener_mixin.dart';
import '../core/view_model/view_model.dart';
import '../design/design_system.dart';
import '../l10n/app_strings.dart';
import '../models/ble_device.dart';
import '../services/animation_service.dart';
import '../services/error_handling_service.dart' show UserAction;
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import '../view_models/simple_scanner_view_model.dart';
import '../widgets/ble/device_list_widget.dart';
import '../widgets/update/update_notification_banner.dart';
import '../widgets/ble/control_panel_widget.dart';
import '../widgets/ble/scanning_indicator_widget.dart';
import '../widgets/ble/connected_device_card_widget.dart';
import '../widgets/ble/quick_stats_widget.dart';
import '../widgets/ble/device_grid_widget.dart';
import '../widgets/ble/device_details_dialog.dart';
import '../widgets/ble/device_search_widget.dart';
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

class _SimpleScannerContentState extends State<_SimpleScannerContent>
    with NotificationListenerMixin<_SimpleScannerContent> {
  SimpleScannerViewModel get viewModel => widget.viewModel;

  StreamSubscription<BleDeviceModel>? _justConnectedSubscription;

  @override
  Stream<NotificationModel> get notificationStream => viewModel.notificationStream;

  @override
  void initState() {
    super.initState();
    initializeNotificationListener();
    _justConnectedSubscription =
        viewModel.justConnectedStream.listen(_onJustConnected);
  }

  @override
  void dispose() {
    _justConnectedSubscription?.cancel();
    disposeNotificationListener();
    super.dispose();
  }

  void _onJustConnected(BleDeviceModel device) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(AppStrings.justConnectedSnackBar(device.displayName)),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: AppStrings.justConnectedSnackBarAction,
          onPressed: _openCommandInterface,
        ),
      ),
    );
  }

  void _openCommandInterface() {
    Navigator.of(context).push(
      AnimationService.createPageTransition(
        page: const CommandInterfaceView(),
        type: PageTransitionType.slideFromBottom,
      ),
    );
  }

  /// Build the blocking-error scaffold shown when the BLE environment
  /// isn't ready (Bluetooth off, permission denied, location service off).
  Widget _buildBlockingErrorScaffold(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final error = viewModel.currentError!;
    final actions = viewModel.errorActions;
    final message = viewModel.errorMessageText;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appTitle),
        backgroundColor: colorScheme.inversePrimary,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: EdgeInsets.all(DesignTokens.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bluetooth_disabled,
                  size: 72,
                  color: colorScheme.error,
                ),
                SizedBox(height: DesignTokens.spacingM),
                Text(
                  AppStrings.bluetoothNotReadyTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DesignTokens.spacingM),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DesignTokens.spacingS),
                Text(
                  '(${error.code})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.6),
                        fontFamily: 'monospace',
                      ),
                ),
                SizedBox(height: DesignTokens.spacingL),
                if (actions.isNotEmpty) ...[
                  Text(
                    AppStrings.howToFixCaption,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: DesignTokens.spacingS),
                  ...actions.map(
                    (action) => Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: DesignTokens.spacingXS,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: action.isPrimary
                            ? FilledButton(
                                onPressed: () => _runRecoveryAction(action),
                                child: Text(action.label),
                              )
                            : OutlinedButton(
                                onPressed: () => _runRecoveryAction(action),
                                child: Text(action.label),
                              ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: DesignTokens.spacingM),
                TextButton(
                  onPressed: () => viewModel.clearError(),
                  child: const Text(AppStrings.cancel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _runRecoveryAction(UserAction action) {
    final cb = action.action;
    if (cb == null) return;
    // Optimistically dismiss the error screen so the user immediately sees
    // the scanner again while the recovery runs (e.g. FlutterBluePlus.turnOn
    // is fire-and-forget async and won't notify us on success). If recovery
    // ultimately fails, BleService re-emits an AppError via errorStream and
    // this scaffold comes back automatically.
    viewModel.clearError();
    cb();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (!viewModel.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.appTitle),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: DesignTokens.spacingML),
              const Text(AppStrings.initializingBluetooth),
            ],
          ),
        ),
      );
    }

    // Blocking error state — show recovery actions instead of the scanner.
    if (viewModel.hasBlockingError) {
      return _buildBlockingErrorScaffold(context);
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
      title: const Text(AppStrings.appTitle),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        // Search Button
        DeviceSearchWidget(
          onSearchChanged: viewModel.setSearchQuery,
          onSearchClosed: viewModel.clearSearch,
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
      tooltip: AppStrings.moreSettings,
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
              const Text(AppStrings.checkForUpdates),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'update_settings',
          child: Row(
            children: [
              const Icon(Icons.system_update_alt),
              SizedBox(width: DesignTokens.spacingSM),
              const Text(AppStrings.updateSettings),
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
          final colorScheme = Theme.of(context).colorScheme;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacingXS),
                child: IconButton.filled(
                  icon: const Icon(Icons.chat),
                  onPressed: _openCommandInterface,
                  tooltip: AppStrings.commandInterface,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.bluetooth_connected),
                onPressed: () => _showConnectedDeviceInfo(snapshot.data!),
                tooltip: AppStrings.deviceInfo,
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
        StreamBuilder<BleDeviceModel?>(
          stream: viewModel.connectedDeviceStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingM,
                  vertical: DesignTokens.spacingS,
                ),
                child: _buildConnectedDeviceCard(snapshot.data!),
              );
            }
            return const SizedBox.shrink();
          },
        ),
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
                        AppStrings.availableDevices,
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
