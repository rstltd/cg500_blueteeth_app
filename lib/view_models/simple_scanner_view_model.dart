import 'package:flutter/material.dart' show IconData;

import '../controllers/ble_controller_interface.dart';
import '../controllers/app_update_manager.dart';
import '../core/service_locator.dart' show getIt;
import '../core/view_model/view_model.dart';
import '../models/ble_device.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';

/// ViewModel for the Simple Scanner View.
///
/// Manages:
/// - BLE controller state and streams
/// - Theme mode state
/// - Update manager access
/// - Notification stream
///
/// Example usage:
/// ```dart
/// ViewModelProvider<SimpleScannerViewModel>(
///   create: () => SimpleScannerViewModel(),
///   builder: (context, viewModel, child) {
///     return SimpleScannerContent(viewModel: viewModel);
///   },
/// )
/// ```
class SimpleScannerViewModel extends BaseViewModel {
  /// Creates a SimpleScannerViewModel.
  ///
  /// [controller] - Optional BLE controller for dependency injection (testing).
  /// [themeService] - Optional theme service for dependency injection (testing).
  /// [updateManager] - Optional update manager for dependency injection (testing).
  /// If null, services are retrieved from the service locator.
  SimpleScannerViewModel({
    BleControllerInterface? controller,
    ThemeService? themeService,
    AppUpdateManager? updateManager,
  })  : _injectedController = controller,
        _injectedThemeService = themeService,
        _injectedUpdateManager = updateManager;

  final BleControllerInterface? _injectedController;
  final ThemeService? _injectedThemeService;
  final AppUpdateManager? _injectedUpdateManager;

  late final BleControllerInterface _controller;
  late final ThemeService _themeService;
  late final AppUpdateManager _updateManager;

  // Local state
  List<BleDeviceModel> _devices = [];
  bool _isScanning = false;
  BleDeviceModel? _connectedDevice;
  AppThemeMode _themeMode = AppThemeMode.system;
  String _searchQuery = '';

  // --- Getters ---

  /// The BLE controller instance.
  BleControllerInterface get controller => _controller;

  /// The theme service instance.
  ThemeService get themeService => _themeService;

  /// The update manager instance.
  AppUpdateManager get updateManager => _updateManager;

  /// List of scanned BLE devices (unfiltered).
  List<BleDeviceModel> get devices => _devices;

  /// Current search query.
  String get searchQuery => _searchQuery;

  /// Whether search is active.
  bool get isSearching => _searchQuery.isNotEmpty;

  /// Filtered list of devices based on search query.
  List<BleDeviceModel> get filteredDevices {
    if (_searchQuery.isEmpty) return _devices;

    final lowerQuery = _searchQuery.toLowerCase();
    return _devices.where((device) {
      final name = device.displayName.toLowerCase();
      final id = device.id.toLowerCase();
      return name.contains(lowerQuery) || id.contains(lowerQuery);
    }).toList();
  }

  /// Whether scanning is in progress.
  bool get isScanning => _isScanning;

  /// The currently connected device.
  BleDeviceModel? get connectedDevice => _connectedDevice;

  /// Whether a device is connected.
  bool get hasConnectedDevice => _connectedDevice != null;

  /// The current theme mode.
  AppThemeMode get themeMode => _themeMode;

  /// Notification stream for UI display.
  Stream<NotificationModel> get notificationStream =>
      _controller.notificationStream;

  // --- Stream Getters (for StreamBuilder widgets) ---

  /// Stream of scanned devices.
  Stream<List<BleDeviceModel>> get devicesStream => _controller.devicesStream;

  /// Stream of scanning state.
  Stream<bool> get scanningStream => _controller.scanningStream;

  /// Stream of connected device.
  Stream<BleDeviceModel?> get connectedDeviceStream =>
      _controller.connectedDeviceStream;

  /// Stream of theme mode.
  Stream<AppThemeMode> get themeModeStream => _themeService.themeModeStream;

  @override
  Future<void> onInit() async {
    // Use injected services or get from service locator
    _controller = _injectedController ?? getIt<BleControllerInterface>();
    _themeService = _injectedThemeService ?? getIt<ThemeService>();
    _updateManager = _injectedUpdateManager ?? getIt<AppUpdateManager>();

    // Initialize controller
    await _controller.initialize();

    // Subscribe to BLE streams
    subscribe<List<BleDeviceModel>>(
      _controller.devicesStream,
      _onDevicesChanged,
    );
    subscribe<bool>(
      _controller.scanningStream,
      _onScanningChanged,
    );
    subscribe<BleDeviceModel?>(
      _controller.connectedDeviceStream,
      _onConnectedDeviceChanged,
    );

    // Subscribe to theme changes
    subscribe<AppThemeMode>(
      _themeService.themeModeStream,
      _onThemeModeChanged,
    );

    // Set initial state
    _devices = _controller.scannedDevices;
    _isScanning = _controller.isScanning;
    _connectedDevice = _controller.connectedDevice;
    _themeMode = _themeService.currentThemeMode;
  }

  // --- Stream Handlers ---

  void _onDevicesChanged(List<BleDeviceModel> devices) {
    _devices = devices;
    safeNotifyListeners();
  }

  void _onScanningChanged(bool isScanning) {
    _isScanning = isScanning;
    safeNotifyListeners();
  }

  void _onConnectedDeviceChanged(BleDeviceModel? device) {
    _connectedDevice = device;
    safeNotifyListeners();
  }

  void _onThemeModeChanged(AppThemeMode mode) {
    _themeMode = mode;
    safeNotifyListeners();
  }

  // --- BLE Actions ---

  /// Start scanning for BLE devices.
  Future<bool> startScanning({Duration? timeout}) async {
    return await _controller.startScanning(timeout: timeout);
  }

  /// Stop scanning for BLE devices.
  Future<void> stopScanning() async {
    await _controller.stopScanning();
  }

  /// Connect to a BLE device.
  Future<bool> connectToDevice(String deviceId) async {
    return await _controller.connectToDevice(deviceId);
  }

  /// Disconnect from the connected device.
  Future<void> disconnectDevice() async {
    await _controller.disconnectDevice();
  }

  /// Clear the list of scanned devices.
  void clearDevices() {
    _controller.clearDevices();
  }

  /// Toggle favorite status of a device.
  BleDeviceModel toggleDeviceFavorite(BleDeviceModel device) {
    return device.toggleFavorite();
  }

  /// Set the search query for filtering devices.
  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      safeNotifyListeners();
    }
  }

  /// Clear the search query.
  void clearSearch() {
    setSearchQuery('');
  }

  // --- Theme Actions ---

  /// Toggle between light and dark theme.
  void toggleTheme() {
    _themeService.toggleTheme();
  }

  /// Get the current theme mode icon.
  IconData get themeModeIcon => _themeService.themeModeIcon;

  /// Get the current theme mode description.
  String get themeModeDescription => _themeService.themeModeDescription;

  // --- Update Actions ---

  /// Check for updates with UI feedback.
  Future<void> checkForUpdates({bool force = false}) async {
    await _updateManager.checkForUpdatesWithUI(force: force);
  }
}
