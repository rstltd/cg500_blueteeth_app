import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cg500_blueteeth_app/core/interfaces/network_service_interface.dart';
import 'package:cg500_blueteeth_app/core/interfaces/notification_service_interface.dart';
import 'package:cg500_blueteeth_app/core/interfaces/permission_service_interface.dart';
import 'package:cg500_blueteeth_app/core/interfaces/ble_service_interface.dart';
import 'package:cg500_blueteeth_app/core/interfaces/update_service_interface.dart';
import 'package:cg500_blueteeth_app/core/interfaces/error_handling_service_interface.dart';
import 'package:cg500_blueteeth_app/core/interfaces/update_ui_delegate.dart';
import 'package:cg500_blueteeth_app/core/interfaces/ble_notification_delegate.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/models/update_preferences.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';

// Re-export MockBleController for convenience
export 'mock_ble_controller.dart';

// Re-export mock factories for convenient test data creation
export 'mock_factories.dart';

/// Mock implementation of NetworkServiceInterface for testing
class MockNetworkService implements NetworkServiceInterface {
  final StreamController<NetworkStatus> _networkController =
      StreamController<NetworkStatus>.broadcast();
  NetworkStatus _currentStatus = NetworkStatus.wifi;

  // Configurable mock behavior
  NetworkStatus? mockStatus;
  bool? mockIsSuitableForDownload;

  @override
  Stream<NetworkStatus> get networkStream => _networkController.stream;

  @override
  NetworkStatus get currentStatus => mockStatus ?? _currentStatus;

  void setStatus(NetworkStatus status) {
    _currentStatus = status;
    _networkController.add(status);
  }

  @override
  Future<bool> initialize() async => true;

  @override
  bool isSuitableForDownload({required bool wifiOnly}) {
    if (mockIsSuitableForDownload != null) {
      return mockIsSuitableForDownload!;
    }
    final status = mockStatus ?? _currentStatus;
    if (wifiOnly) {
      return status == NetworkStatus.wifi;
    }
    return status != NetworkStatus.none;
  }

  @override
  String getStatusDescription() {
    switch (_currentStatus) {
      case NetworkStatus.wifi:
        return 'Connected via WiFi';
      case NetworkStatus.mobile:
        return 'Connected via mobile data';
      case NetworkStatus.none:
        return 'No internet connection';
      case NetworkStatus.unknown:
        return 'Network status unknown';
    }
  }

  @override
  String getNetworkTypeDisplayName() {
    switch (_currentStatus) {
      case NetworkStatus.wifi:
        return 'WiFi';
      case NetworkStatus.mobile:
        return 'Mobile Data';
      case NetworkStatus.none:
        return 'No Connection';
      case NetworkStatus.unknown:
        return 'Unknown';
    }
  }

  @override
  String estimateDownloadTime(int fileSizeBytes) {
    return '~5s';
  }

  @override
  void dispose() {
    _networkController.close();
  }
}

/// Mock implementation of NotificationServiceInterface for testing
class MockNotificationService implements NotificationServiceInterface {
  final StreamController<NotificationModel> _notificationController =
      StreamController<NotificationModel>.broadcast();
  final List<NotificationModel> _notifications = [];

  @override
  Stream<NotificationModel> get notifications => _notificationController.stream;

  List<NotificationModel> get allNotifications =>
      List.unmodifiable(_notifications);

  @override
  void showInfo({required String title, required String message}) {
    _addNotification(title, message, NotificationType.info);
  }

  @override
  void showSuccess({required String title, required String message}) {
    _addNotification(title, message, NotificationType.success);
  }

  @override
  void showWarning({required String title, required String message}) {
    _addNotification(title, message, NotificationType.warning);
  }

  @override
  void showError({required String title, required String message}) {
    _addNotification(title, message, NotificationType.error);
  }

  @override
  void showConnectionStatus({
    required String title,
    required String message,
    required bool isConnected,
  }) {
    _addNotification(
      title,
      message,
      isConnected ? NotificationType.success : NotificationType.info,
    );
  }

  @override
  void showScanningStatus({
    required String title,
    required String message,
    required bool isScanning,
  }) {
    _addNotification(title, message, NotificationType.info);
  }

  void _addNotification(String title, String message, NotificationType type) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );
    _notifications.add(notification);
    _notificationController.add(notification);
  }

  void clear() {
    _notifications.clear();
  }

  @override
  void dispose() {
    _notificationController.close();
  }
}

/// Mock implementation of PermissionServiceInterface for testing
class MockPermissionService implements PermissionServiceInterface {
  bool _hasPermissions = true;
  bool _locationEnabled = true;

  void setHasPermissions(bool value) {
    _hasPermissions = value;
  }

  void setLocationEnabled(bool value) {
    _locationEnabled = value;
  }

  @override
  Future<bool> hasBluetoothPermissions() async => _hasPermissions;

  @override
  Future<bool> requestBluetoothPermissions() async => _hasPermissions;

  @override
  Future<bool> isLocationEnabled() async => _locationEnabled;

  @override
  Future<void> openAppSettings() async {}
}

/// Mock implementation of BleServiceInterface for testing
class MockBleService implements BleServiceInterface {
  final StreamController<List<BleDeviceModel>> _devicesController =
      StreamController<List<BleDeviceModel>>.broadcast();
  final StreamController<bool> _scanningController =
      StreamController<bool>.broadcast();
  final StreamController<BleDeviceModel?> _connectedDeviceController =
      StreamController<BleDeviceModel?>.broadcast();
  final StreamController<String> _commandResponseController =
      StreamController<String>.broadcast();

  List<BleDeviceModel> _devices = [];
  BleDeviceModel? _connectedDevice;
  bool _isScanning = false;
  bool _isInitialized = false;

  // Configurable behavior for testing different scenarios
  bool _initializeSuccess = true;
  bool _initializeThrowError = false;
  String _initializeErrorMessage = 'Mock initialize error';

  bool _startScanningThrowError = false;
  String _startScanningErrorMessage = 'Mock scanning error';

  bool _stopScanningThrowError = false;
  String _stopScanningErrorMessage = 'Mock stop scanning error';

  bool _connectSuccess = true;
  bool _connectThrowError = false;
  String _connectErrorMessage = 'Mock connect error';

  bool _disconnectThrowError = false;
  String _disconnectErrorMessage = 'Mock disconnect error';

  int _discoverServicesCount = 0;
  bool _discoverServicesThrowError = false;
  String _discoverServicesErrorMessage = 'Mock service discovery error';

  bool _sendCommandSuccess = true;
  bool _sendCommandThrowError = false;
  String _sendCommandErrorMessage = 'Mock send command error';

  /// Configure initialize behavior
  void configureInitialize({
    bool success = true,
    bool throwError = false,
    String errorMessage = 'Mock initialize error',
  }) {
    _initializeSuccess = success;
    _initializeThrowError = throwError;
    _initializeErrorMessage = errorMessage;
  }

  /// Configure startScanning behavior
  void configureStartScanning({
    bool throwError = false,
    String errorMessage = 'Mock scanning error',
  }) {
    _startScanningThrowError = throwError;
    _startScanningErrorMessage = errorMessage;
  }

  /// Configure stopScanning behavior
  void configureStopScanning({
    bool throwError = false,
    String errorMessage = 'Mock stop scanning error',
  }) {
    _stopScanningThrowError = throwError;
    _stopScanningErrorMessage = errorMessage;
  }

  /// Configure connect behavior
  void configureConnect({
    bool success = true,
    bool throwError = false,
    String errorMessage = 'Mock connect error',
  }) {
    _connectSuccess = success;
    _connectThrowError = throwError;
    _connectErrorMessage = errorMessage;
  }

  /// Configure disconnect behavior
  void configureDisconnect({
    bool throwError = false,
    String errorMessage = 'Mock disconnect error',
  }) {
    _disconnectThrowError = throwError;
    _disconnectErrorMessage = errorMessage;
  }

  /// Configure discoverServices behavior
  void configureDiscoverServices({
    int serviceCount = 0,
    bool throwError = false,
    String errorMessage = 'Mock service discovery error',
  }) {
    _discoverServicesCount = serviceCount;
    _discoverServicesThrowError = throwError;
    _discoverServicesErrorMessage = errorMessage;
  }

  /// Configure sendCommand behavior
  void configureSendCommand({
    bool success = true,
    bool throwError = false,
    String errorMessage = 'Mock send command error',
  }) {
    _sendCommandSuccess = success;
    _sendCommandThrowError = throwError;
    _sendCommandErrorMessage = errorMessage;
  }

  /// Reset all configurable behavior to defaults
  void resetConfiguration() {
    _initializeSuccess = true;
    _initializeThrowError = false;
    _initializeErrorMessage = 'Mock initialize error';
    _startScanningThrowError = false;
    _startScanningErrorMessage = 'Mock scanning error';
    _stopScanningThrowError = false;
    _stopScanningErrorMessage = 'Mock stop scanning error';
    _connectSuccess = true;
    _connectThrowError = false;
    _connectErrorMessage = 'Mock connect error';
    _disconnectThrowError = false;
    _disconnectErrorMessage = 'Mock disconnect error';
    _discoverServicesCount = 0;
    _discoverServicesThrowError = false;
    _discoverServicesErrorMessage = 'Mock service discovery error';
    _sendCommandSuccess = true;
    _sendCommandThrowError = false;
    _sendCommandErrorMessage = 'Mock send command error';
  }

  @override
  Stream<List<BleDeviceModel>> get devicesStream => _devicesController.stream;
  @override
  Stream<bool> get scanningStream => _scanningController.stream;
  @override
  Stream<BleDeviceModel?> get connectedDeviceStream =>
      _connectedDeviceController.stream;
  @override
  Stream<String> get commandResponseStream => _commandResponseController.stream;

  @override
  List<BleDeviceModel> get scannedDevices => List.unmodifiable(_devices);
  @override
  BleDeviceModel? get connectedDevice => _connectedDevice;
  @override
  bool get isScanning => _isScanning;
  @override
  bool get isInitialized => _isInitialized;

  void setDevices(List<BleDeviceModel> devices) {
    _devices = devices;
    _devicesController.add(devices);
  }

  @override
  Future<bool> initialize() async {
    if (_initializeThrowError) {
      throw Exception(_initializeErrorMessage);
    }
    _isInitialized = _initializeSuccess;
    return _initializeSuccess;
  }

  @override
  Future<bool> isBluetoothEnabled() async => true;

  @override
  Future<void> turnOnBluetooth() async {}

  @override
  Future<bool> startScanning({Duration timeout = const Duration(seconds: 15)}) async {
    if (_startScanningThrowError) {
      throw Exception(_startScanningErrorMessage);
    }
    _isScanning = true;
    _scanningController.add(true);
    return true;
  }

  @override
  Future<void> stopScanning() async {
    if (_stopScanningThrowError) {
      throw Exception(_stopScanningErrorMessage);
    }
    _isScanning = false;
    _scanningController.add(false);
  }

  @override
  void clearScannedDevices() {
    _devices = [];
    _devicesController.add([]);
  }

  @override
  Future<bool> connectToDevice(String deviceId) async {
    if (_connectThrowError) {
      throw Exception(_connectErrorMessage);
    }
    if (!_connectSuccess) {
      return false;
    }
    _connectedDevice = _devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => BleDeviceModel(id: deviceId, name: 'Mock', displayName: 'Mock'),
    );
    _connectedDeviceController.add(_connectedDevice);
    return true;
  }

  @override
  Future<void> disconnectDevice() async {
    if (_disconnectThrowError) {
      throw Exception(_disconnectErrorMessage);
    }
    _connectedDevice = null;
    _connectedDeviceController.add(null);
  }

  @override
  Future<List<BleServiceModel>> discoverServices(String deviceId) async {
    if (_discoverServicesThrowError) {
      throw Exception(_discoverServicesErrorMessage);
    }
    if (_discoverServicesCount == 0) {
      return [];
    }
    // Generate mock services based on configured count
    return List.generate(
      _discoverServicesCount,
      (index) => BleServiceModel(
        uuid: '0000180${index}-0000-1000-8000-00805f9b34fb',
        displayName: 'Mock Service $index',
        characteristics: [],
      ),
    );
  }

  @override
  Future<bool> sendCommand(String command) async {
    if (_sendCommandThrowError) {
      throw Exception(_sendCommandErrorMessage);
    }
    // Check if connected - return false when not connected
    if (_connectedDevice == null) {
      return false;
    }
    if (!_sendCommandSuccess) {
      return false;
    }
    _commandResponseController.add('Response: $command');
    return true;
  }

  @override
  Map<String, dynamic> getCommandInfo() {
    return {
      'hasCommandChannel': true,
      'hasResponseChannel': true,
      'commandUuid': 'mock-command-uuid',
      'responseUuid': 'mock-response-uuid',
      'mtu': 517,
    };
  }

  @override
  void dispose() {
    _devicesController.close();
    _scanningController.close();
    _connectedDeviceController.close();
    _commandResponseController.close();
  }
}

/// Mock implementation of UpdateServiceInterface for testing
class MockUpdateService implements UpdateServiceInterface {
  final StreamController<UpdateInfo> _updateController =
      StreamController<UpdateInfo>.broadcast();
  final StreamController<DownloadProgress> _downloadController =
      StreamController<DownloadProgress>.broadcast();

  UpdatePreferences? _preferences;
  UpdateInfo? _pendingUpdate;

  // Configurable behavior for testing different scenarios
  bool _shouldDownloadSucceed = true;
  bool _shouldInstallSucceed = true;
  bool _canInstall = true;
  List<DownloadProgress>? _downloadProgressSequence;
  Duration _downloadDelay = Duration.zero;
  String _mockApkPath = '/mock/path/app.apk';
  final List<String> _skippedVersions = [];
  int _downloadAttempts = 0;
  int _installAttempts = 0;

  @override
  Stream<UpdateInfo> get updateStream => _updateController.stream;
  @override
  Stream<DownloadProgress> get downloadStream => _downloadController.stream;
  @override
  UpdatePreferences? get preferences => _preferences;

  // Test inspection getters
  List<String> get skippedVersions => List.unmodifiable(_skippedVersions);
  int get downloadAttempts => _downloadAttempts;
  int get installAttempts => _installAttempts;

  void setPendingUpdate(UpdateInfo? update) {
    _pendingUpdate = update;
    if (update != null) {
      _updateController.add(update);
    }
  }

  /// Configure download behavior for testing
  void configureDownload({
    bool succeed = true,
    List<DownloadProgress>? progressSequence,
    Duration delay = Duration.zero,
    String apkPath = '/mock/path/app.apk',
  }) {
    _shouldDownloadSucceed = succeed;
    _downloadProgressSequence = progressSequence;
    _downloadDelay = delay;
    _mockApkPath = apkPath;
  }

  /// Configure install behavior for testing
  void configureInstall({
    bool succeed = true,
    bool canInstall = true,
  }) {
    _shouldInstallSucceed = succeed;
    _canInstall = canInstall;
  }

  /// Emit a download progress event (for testing stream listeners)
  void emitDownloadProgress(DownloadProgress progress) {
    _downloadController.add(progress);
  }

  /// Reset all mock state
  void reset() {
    _pendingUpdate = null;
    _shouldDownloadSucceed = true;
    _shouldInstallSucceed = true;
    _canInstall = true;
    _downloadProgressSequence = null;
    _downloadDelay = Duration.zero;
    _mockApkPath = '/mock/path/app.apk';
    _skippedVersions.clear();
    _downloadAttempts = 0;
    _installAttempts = 0;
    _preferences = null;
  }

  @override
  Future<bool> initialize() async {
    _preferences = UpdatePreferences();
    return true;
  }

  @override
  Future<UpdateInfo?> checkForUpdates({bool showNotification = true}) async {
    return _pendingUpdate;
  }

  @override
  Future<String?> downloadUpdate(UpdateInfo updateInfo) async {
    _downloadAttempts++;

    if (_downloadDelay > Duration.zero) {
      await Future.delayed(_downloadDelay);
    }

    if (_downloadProgressSequence != null) {
      // Emit custom progress sequence
      for (final progress in _downloadProgressSequence!) {
        _downloadController.add(progress);
        await Future.delayed(const Duration(milliseconds: 10));
      }
    } else {
      // Default: emit single completion progress
      _downloadController.add(DownloadProgress(
        progress: 1.0,
        downloadedBytes: updateInfo.downloadSize,
        totalBytes: updateInfo.downloadSize,
        status: 'Complete',
        filePath: _mockApkPath,
      ));
    }

    return _shouldDownloadSucceed ? _mockApkPath : null;
  }

  @override
  Future<void> cleanupDownloads({String? keepVersion}) async {}

  @override
  Future<bool> installUpdate(String apkPath) async {
    _installAttempts++;
    return _shouldInstallSucceed;
  }

  @override
  Future<bool> canInstallApks() async => _canInstall;

  @override
  Future<void> requestInstallPermission() async {}

  @override
  Future<Map<String, dynamic>> diagnosePermissions() async {
    return {'supported': true};
  }

  @override
  Map<String, String> getCurrentVersionInfo() {
    return {
      'version': '1.0.0',
      'buildNumber': '1',
    };
  }

  @override
  Future<void> skipVersion(String version) async {
    _skippedVersions.add(version);
  }

  @override
  Future<void> updatePreferences(UpdatePreferences newPreferences) async {
    _preferences = newPreferences;
  }

  @override
  bool shouldAutoDownload(UpdateInfo updateInfo) {
    return _preferences?.autoDownloadEnabled ?? false;
  }

  @override
  void dispose() {
    _updateController.close();
    _downloadController.close();
  }
}

/// Mock implementation of ErrorHandlingServiceInterface for testing
class MockErrorHandlingService implements ErrorHandlingServiceInterface {
  final StreamController<AppError> _errorController =
      StreamController<AppError>.broadcast();
  final List<AppError> _errorHistory = [];

  @override
  Stream<AppError> get errorStream => _errorController.stream;

  @override
  List<AppError> get errorHistory => List.unmodifiable(_errorHistory);

  @override
  Future<void> handleError(AppError error) async {
    _errorHistory.insert(0, error);
    if (_errorHistory.length > 100) {
      _errorHistory.removeLast();
    }
    _errorController.add(error);
  }

  @override
  String getErrorMessage(AppError error) {
    return error.message;
  }

  @override
  List<UserAction> getErrorRecoveryActions(AppError error) {
    if (error.retryAction != null) {
      return [
        UserAction(
          label: 'Retry',
          action: error.retryAction,
          isPrimary: true,
        ),
      ];
    }
    return [];
  }

  @override
  void clearHistory() {
    _errorHistory.clear();
  }

  @override
  void dispose() {
    _errorController.close();
  }
}

/// Mock implementation of BleNotificationDelegate for testing
class MockBleNotificationDelegate implements BleNotificationDelegate {
  // Track all delegate calls for verification
  final List<String> calls = [];

  // Specific call tracking
  int initializeSuccessCount = 0;
  int initializeFailedCount = 0;
  final List<String> initializeErrors = [];
  int scanStartedCount = 0;
  int scanStoppedCount = 0;
  final List<String> scanErrors = [];
  final List<String> stopScanErrors = [];
  int connectingCount = 0;
  int connectedCount = 0;
  final List<String> connectionErrors = [];
  final List<String> disconnectErrors = [];
  int discoveringServicesCount = 0;
  final List<int> servicesFoundCounts = [];
  int noServicesFoundCount = 0;
  final List<String> serviceDiscoveryErrors = [];
  int emptyCommandCount = 0;
  final List<String> commandErrors = [];
  int devicesClearedCount = 0;

  @override
  void onInitializeSuccess() {
    calls.add('onInitializeSuccess');
    initializeSuccessCount++;
  }

  @override
  void onInitializeFailed() {
    calls.add('onInitializeFailed');
    initializeFailedCount++;
  }

  @override
  void onInitializeError(String error) {
    calls.add('onInitializeError: $error');
    initializeErrors.add(error);
  }

  @override
  void onScanStarted() {
    calls.add('onScanStarted');
    scanStartedCount++;
  }

  @override
  void onScanStopped() {
    calls.add('onScanStopped');
    scanStoppedCount++;
  }

  @override
  void onScanError(String error) {
    calls.add('onScanError: $error');
    scanErrors.add(error);
  }

  @override
  void onStopScanError(String error) {
    calls.add('onStopScanError: $error');
    stopScanErrors.add(error);
  }

  @override
  void onConnecting() {
    calls.add('onConnecting');
    connectingCount++;
  }

  @override
  void onConnected() {
    calls.add('onConnected');
    connectedCount++;
  }

  @override
  void onConnectionError(String error) {
    calls.add('onConnectionError: $error');
    connectionErrors.add(error);
  }

  @override
  void onDisconnectError(String error) {
    calls.add('onDisconnectError: $error');
    disconnectErrors.add(error);
  }

  @override
  void onDiscoveringServices() {
    calls.add('onDiscoveringServices');
    discoveringServicesCount++;
  }

  @override
  void onServicesFound(int count) {
    calls.add('onServicesFound: $count');
    servicesFoundCounts.add(count);
  }

  @override
  void onNoServicesFound() {
    calls.add('onNoServicesFound');
    noServicesFoundCount++;
  }

  @override
  void onServiceDiscoveryError(String error) {
    calls.add('onServiceDiscoveryError: $error');
    serviceDiscoveryErrors.add(error);
  }

  @override
  void onEmptyCommand() {
    calls.add('onEmptyCommand');
    emptyCommandCount++;
  }

  @override
  void onCommandError(String error) {
    calls.add('onCommandError: $error');
    commandErrors.add(error);
  }

  @override
  void onDevicesCleared() {
    calls.add('onDevicesCleared');
    devicesClearedCount++;
  }

  /// Reset all tracked calls
  void reset() {
    calls.clear();
    initializeSuccessCount = 0;
    initializeFailedCount = 0;
    initializeErrors.clear();
    scanStartedCount = 0;
    scanStoppedCount = 0;
    scanErrors.clear();
    stopScanErrors.clear();
    connectingCount = 0;
    connectedCount = 0;
    connectionErrors.clear();
    disconnectErrors.clear();
    discoveringServicesCount = 0;
    servicesFoundCounts.clear();
    noServicesFoundCount = 0;
    serviceDiscoveryErrors.clear();
    emptyCommandCount = 0;
    commandErrors.clear();
    devicesClearedCount = 0;
  }
}

/// Mock implementation of UpdateUIDelegate for testing
class MockUpdateUIDelegate implements UpdateUIDelegate {
  // Track all UI delegate calls for verification
  final List<String> calls = [];
  final List<String> installationStartedCalls = [];
  final List<String> installationFailedCalls = [];
  final List<String> installationErrorCalls = [];
  final List<String> skipVersionConfirmationCalls = [];
  final List<String> versionSkippedCalls = [];
  final List<int> closeDialogsCalls = [];

  // Configurable behavior
  bool skipVersionConfirmationResult = true;

  @override
  void showInstallationStarted(BuildContext context) {
    calls.add('showInstallationStarted');
    installationStartedCalls.add('called');
  }

  @override
  void showInstallationFailed(BuildContext context) {
    calls.add('showInstallationFailed');
    installationFailedCalls.add('called');
  }

  @override
  void showInstallationError(BuildContext context, String errorMessage) {
    calls.add('showInstallationError: $errorMessage');
    installationErrorCalls.add(errorMessage);
  }

  @override
  Future<bool> showSkipVersionConfirmation(
    BuildContext context,
    String version,
  ) async {
    calls.add('showSkipVersionConfirmation: $version');
    skipVersionConfirmationCalls.add(version);
    return skipVersionConfirmationResult;
  }

  @override
  void showVersionSkipped(
    BuildContext context,
    String version,
    VoidCallback onUndo,
  ) {
    calls.add('showVersionSkipped: $version');
    versionSkippedCalls.add(version);
  }

  @override
  void closeDialogs(BuildContext context, {int count = 1}) {
    calls.add('closeDialogs: $count');
    closeDialogsCalls.add(count);
  }

  /// Reset all tracked calls
  void reset() {
    calls.clear();
    installationStartedCalls.clear();
    installationFailedCalls.clear();
    installationErrorCalls.clear();
    skipVersionConfirmationCalls.clear();
    versionSkippedCalls.clear();
    closeDialogsCalls.clear();
    skipVersionConfirmationResult = true;
  }
}
