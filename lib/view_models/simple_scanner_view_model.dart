import 'dart:async';

import 'package:flutter/material.dart' show IconData;

import '../controllers/ble_controller_interface.dart';
import '../controllers/update_controller.dart';
import '../core/service_locator.dart' show getIt;
import '../core/view_model/view_model.dart';
import '../models/ble_device.dart';
import '../models/connection_state.dart';
import '../services/error_handling_service.dart';
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
    UpdateController? updateManager,
    ErrorHandlingService? errorHandlingService,
  })  : _injectedController = controller,
        _injectedThemeService = themeService,
        _injectedUpdateManager = updateManager,
        _injectedErrorHandlingService = errorHandlingService;

  final BleControllerInterface? _injectedController;
  final ThemeService? _injectedThemeService;
  final UpdateController? _injectedUpdateManager;
  final ErrorHandlingService? _injectedErrorHandlingService;

  late final BleControllerInterface _controller;
  late final ThemeService _themeService;
  late final UpdateController _updateManager;
  late final ErrorHandlingService _errorHandlingService;

  // Local state
  List<BleDeviceModel> _devices = [];
  bool _isScanning = false;
  BleDeviceModel? _connectedDevice;
  AppThemeMode _themeMode = AppThemeMode.system;
  String _searchQuery = '';

  /// The most recent **blocking** error from the BLE pipeline, or null when
  /// the scanner can run normally. Only environment/permission failures
  /// during initialize/scanning are routed here so the View can replace its
  /// content with a structured recovery screen — transient post-connect
  /// errors still flow via the standard notification SnackBar.
  AppError? _currentError;
  AppError? get currentError => _currentError;
  bool get hasBlockingError => _currentError != null;
  List<UserAction> get errorActions => _currentError == null
      ? const []
      : _errorHandlingService.getErrorRecoveryActions(_currentError!);
  String get errorMessageText => _currentError == null
      ? ''
      : _errorHandlingService.getErrorMessage(_currentError!);

  /// Codes considered blocking — reaching one means the user can't continue
  /// without recovering, so we swap in the error scaffold instead of just
  /// flashing a SnackBar.
  static const Set<String> _blockingErrorCodes = {
    'BLE_DISABLED',
    'BLE_UNAVAILABLE',
    'BLUETOOTH_PERMISSION_DENIED',
    'LOCATION_PERMISSION_DENIED',
    'LOCATION_SERVICE_DISABLED',
    'INIT_FAILED',
  };

  /// Emits the device whenever a connection is newly established
  /// (transition from no-device to connected). Used by the View to
  /// surface a one-shot guidance SnackBar — bypasses the notification
  /// verbosity filter so it always reaches the user.
  final StreamController<BleDeviceModel> _justConnectedController =
      StreamController<BleDeviceModel>.broadcast();

  Stream<BleDeviceModel> get justConnectedStream =>
      _justConnectedController.stream;

  // --- Getters ---

  /// The BLE controller instance.
  BleControllerInterface get controller => _controller;

  /// The theme service instance.
  ThemeService get themeService => _themeService;

  /// The update manager instance.
  UpdateController get updateManager => _updateManager;

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
    _updateManager = _injectedUpdateManager ?? getIt<UpdateController>();
    _errorHandlingService =
        _injectedErrorHandlingService ?? getIt<ErrorHandlingService>();

    // Subscribe to AppError stream BEFORE initialize() so we can capture
    // any blocking error raised during startup.
    subscribe<AppError>(_errorHandlingService.errorStream, _onAppError);

    // Auto-dismiss BLE_DISABLED errors when the user re-enables Bluetooth
    // from the system tray (an action that never flows through our UI).
    subscribe<bool>(_controller.adapterOnStream, _onAdapterOn);

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
    // Track whether we were ACTUALLY connected (not just connecting) so
    // the guidance SnackBar fires at the right moment — after the
    // handshake completes, not when BleService first sets the connecting
    // state.
    final wasActuallyConnected =
        _connectedDevice?.connectionState.isConnected ?? false;
    _connectedDevice = device;

    final isNowConnected =
        device != null && device.connectionState.isConnected;

    if (isNowConnected && !wasActuallyConnected) {
      if (!_justConnectedController.isClosed) {
        _justConnectedController.add(device);
      }
      // A successful connection means the environment is healthy — clear
      // any leftover blocking error so the View can return to normal.
      if (_currentError != null) {
        _currentError = null;
      }
    }
    safeNotifyListeners();
  }

  void _onAppError(AppError error) {
    if (_blockingErrorCodes.contains(error.code)) {
      _currentError = error;
      safeNotifyListeners();
    }
  }

  void _onAdapterOn(bool isOn) {
    // Clear a lingering BLE_DISABLED error as soon as the adapter reports ON
    // again — whether the user toggled it from the in-app recovery button or
    // the system quick settings tile.
    if (isOn && _currentError?.code == 'BLE_DISABLED') {
      _currentError = null;
      safeNotifyListeners();
    }
  }

  /// Clear the current blocking error (called after the user runs the
  /// recovery action or chooses to dismiss).
  @override
  void clearError() {
    super.clearError();
    if (_currentError != null) {
      _currentError = null;
      safeNotifyListeners();
    }
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
    // Always show the up-to-date / failure toast when the user triggers
    // this explicitly from the AppBar menu — silent behaviour here made
    // the button look broken.
    await _updateManager.checkForUpdatesWithUI(
      force: force,
      showUpToDateMessage: true,
    );
  }

  @override
  void onDispose() {
    _justConnectedController.close();
    super.onDispose();
  }
}
