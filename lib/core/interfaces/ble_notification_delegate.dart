import '../../services/notification_service.dart';

/// Verbosity level for BLE notifications.
/// Controls how much detail is shown to the user.
enum BleNotificationVerbosity {
  /// Show all notifications including info and success messages
  verbose,
  /// Show only errors and warnings (recommended for most users)
  normal,
  /// Show only error notifications (minimal noise)
  minimal,
  /// Don't show any notifications (silent mode)
  silent,
}

/// SharedPreferences key for BLE notification verbosity
const String bleNotificationVerbosityKey = 'ble_notification_verbosity';

/// BLE event types for notification handling.
/// Each event has properties that determine when it should be shown.
enum BleEvent {
  // Initialization events
  initializeSuccess(isError: false, isWarning: false, isImportant: true,
      defaultTitle: 'Controller Ready',
      defaultMessage: 'BLE Controller initialized successfully'),
  initializeFailed(isError: true, isWarning: false, isImportant: true,
      defaultTitle: 'Initialization Failed',
      defaultMessage: 'Failed to initialize BLE Controller'),
  initializeError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: 'Controller Error',
      defaultMessage: 'Unexpected error during initialization'),

  // Scanning events
  scanStarted(isError: false, isWarning: false, isImportant: false,
      defaultTitle: 'Scanning Started',
      defaultMessage: 'Looking for BLE devices nearby...'),
  scanStopped(isError: false, isWarning: false, isImportant: false,
      defaultTitle: 'Scanning Stopped',
      defaultMessage: 'Device scanning has been stopped'),
  scanError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: 'Scan Error',
      defaultMessage: 'Failed to start scanning'),
  stopScanError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: 'Stop Scan Error',
      defaultMessage: 'Failed to stop scanning'),

  // Connection events
  connecting(isError: false, isWarning: false, isImportant: false,
      defaultTitle: 'Connecting',
      defaultMessage: 'Attempting to connect to device...'),
  connected(isError: false, isWarning: false, isImportant: true,
      defaultTitle: 'Connected',
      defaultMessage: 'Successfully connected to device'),
  connectionError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: 'Connection Failed',
      defaultMessage: 'Failed to connect to device'),
  disconnectError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: 'Disconnect Error',
      defaultMessage: 'Failed to disconnect device'),

  // Service discovery events
  discoveringServices(isError: false, isWarning: false, isImportant: false,
      defaultTitle: 'Discovering Services',
      defaultMessage: 'Exploring device capabilities...'),
  servicesFound(isError: false, isWarning: false, isImportant: true,
      defaultTitle: 'Services Found',
      defaultMessage: 'Discovered services'),
  noServicesFound(isError: false, isWarning: true, isImportant: false,
      defaultTitle: 'No Services',
      defaultMessage: 'No GATT services found on device'),
  serviceDiscoveryError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: 'Service Discovery Error',
      defaultMessage: 'Failed to discover services'),

  // Command events
  emptyCommand(isError: false, isWarning: true, isImportant: false,
      defaultTitle: 'Empty Command',
      defaultMessage: 'Please enter a command to send'),
  commandError(isError: true, isWarning: false, isImportant: true,
      defaultTitle: 'Command Failed',
      defaultMessage: 'Failed to send command'),

  // Device list events
  devicesCleared(isError: false, isWarning: false, isImportant: false,
      defaultTitle: 'Devices Cleared',
      defaultMessage: 'Cleared device list'),
  ;

  final bool isError;
  final bool isWarning;
  final bool isImportant;
  final String defaultTitle;
  final String defaultMessage;

  const BleEvent({
    required this.isError,
    required this.isWarning,
    required this.isImportant,
    required this.defaultTitle,
    required this.defaultMessage,
  });
}

/// Unified delegate for BLE controller notifications.
///
/// This class replaces the previous 4 implementations (Default, Minimal,
/// Configurable, Silent) with a single configurable class that handles
/// all notification behavior based on the verbosity level.
///
/// The delegate separates notification logic from the BLE controller,
/// allowing for easier testing and customization of notification behavior.
///
/// Usage:
/// ```dart
/// final delegate = BleNotificationDelegate(
///   notificationService: myNotificationService,
///   verbosity: BleNotificationVerbosity.minimal,
/// );
///
/// // Change verbosity at runtime
/// delegate.setVerbosity(BleNotificationVerbosity.verbose);
/// ```
class BleNotificationDelegate {
  final NotificationService _notificationService;
  BleNotificationVerbosity _verbosity;

  BleNotificationDelegate(
    this._notificationService, {
    BleNotificationVerbosity verbosity = BleNotificationVerbosity.minimal,
  }) : _verbosity = verbosity;

  /// Get current verbosity level
  BleNotificationVerbosity get verbosity => _verbosity;

  /// Update verbosity level at runtime
  void setVerbosity(BleNotificationVerbosity verbosity) {
    _verbosity = verbosity;
  }

  /// Determine if an event should trigger a notification based on verbosity.
  bool _shouldNotify(BleEvent event) {
    switch (_verbosity) {
      case BleNotificationVerbosity.silent:
        return false;
      case BleNotificationVerbosity.minimal:
        return event.isError;
      case BleNotificationVerbosity.normal:
        return event.isError || event.isWarning;
      case BleNotificationVerbosity.verbose:
        return true;
    }
  }

  /// Unified notification method using BleEvent.
  void _notify(BleEvent event, {String? customMessage}) {
    if (!_shouldNotify(event)) return;

    final message = customMessage ?? event.defaultMessage;

    if (event.isError) {
      _notificationService.showError(
        title: event.defaultTitle,
        message: message,
      );
    } else if (event.isWarning) {
      _notificationService.showWarning(
        title: event.defaultTitle,
        message: message,
      );
    } else if (event.isImportant) {
      _notificationService.showSuccess(
        title: event.defaultTitle,
        message: message,
      );
    } else {
      _notificationService.showInfo(
        title: event.defaultTitle,
        message: message,
      );
    }
  }

  // ============================================
  // Initialization notifications
  // ============================================

  void onInitializeSuccess() => _notify(BleEvent.initializeSuccess);

  void onInitializeFailed() => _notify(BleEvent.initializeFailed);

  void onInitializeError(String error) =>
      _notify(BleEvent.initializeError,
          customMessage: 'Unexpected error during initialization: $error');

  // ============================================
  // Scanning notifications
  // ============================================

  void onScanStarted() => _notify(BleEvent.scanStarted);

  void onScanStopped() => _notify(BleEvent.scanStopped);

  void onScanError(String error) =>
      _notify(BleEvent.scanError, customMessage: 'Failed to start scanning: $error');

  void onStopScanError(String error) =>
      _notify(BleEvent.stopScanError, customMessage: 'Failed to stop scanning: $error');

  // ============================================
  // Connection notifications
  // ============================================

  void onConnecting() => _notify(BleEvent.connecting);

  void onConnected() => _notify(BleEvent.connected);

  void onConnectionError(String error) =>
      _notify(BleEvent.connectionError, customMessage: error);

  void onDisconnectError(String error) =>
      _notify(BleEvent.disconnectError, customMessage: error);

  // ============================================
  // Service discovery notifications
  // ============================================

  void onDiscoveringServices() => _notify(BleEvent.discoveringServices);

  void onServicesFound(int count) =>
      _notify(BleEvent.servicesFound, customMessage: 'Discovered $count service(s)');

  void onNoServicesFound() => _notify(BleEvent.noServicesFound);

  void onServiceDiscoveryError(String error) =>
      _notify(BleEvent.serviceDiscoveryError, customMessage: error);

  // ============================================
  // Command notifications
  // ============================================

  void onEmptyCommand() => _notify(BleEvent.emptyCommand);

  void onCommandError(String error) =>
      _notify(BleEvent.commandError, customMessage: error);

  // ============================================
  // Device list notifications
  // ============================================

  void onDevicesCleared() => _notify(BleEvent.devicesCleared);
}
