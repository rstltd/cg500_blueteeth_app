import '../interfaces/notification_service_interface.dart';

/// Delegate interface for BLE controller notifications.
///
/// This interface abstracts the notification logic from the BLE controller,
/// allowing for easier testing and customization of notification behavior.
abstract class BleNotificationDelegate {
  // Initialization notifications
  void onInitializeSuccess();
  void onInitializeFailed();
  void onInitializeError(String error);

  // Scanning notifications
  void onScanStarted();
  void onScanStopped();
  void onScanError(String error);
  void onStopScanError(String error);

  // Connection notifications
  void onConnecting();
  void onConnected();
  void onConnectionError(String error);
  void onDisconnectError(String error);

  // Service discovery notifications
  void onDiscoveringServices();
  void onServicesFound(int count);
  void onNoServicesFound();
  void onServiceDiscoveryError(String error);

  // Command notifications
  void onEmptyCommand();
  void onCommandError(String error);

  // Device list notifications
  void onDevicesCleared();
}

/// Default implementation of BleNotificationDelegate that uses NotificationServiceInterface.
class DefaultBleNotificationDelegate implements BleNotificationDelegate {
  final NotificationServiceInterface _notificationService;

  const DefaultBleNotificationDelegate(this._notificationService);

  @override
  void onInitializeSuccess() {
    _notificationService.showSuccess(
      title: 'Controller Ready',
      message: 'BLE Controller initialized successfully',
    );
  }

  @override
  void onInitializeFailed() {
    _notificationService.showError(
      title: 'Initialization Failed',
      message: 'Failed to initialize BLE Controller',
    );
  }

  @override
  void onInitializeError(String error) {
    _notificationService.showError(
      title: 'Controller Error',
      message: 'Unexpected error during initialization: $error',
    );
  }

  @override
  void onScanStarted() {
    _notificationService.showInfo(
      title: 'Scanning Started',
      message: 'Looking for BLE devices nearby...',
    );
  }

  @override
  void onScanStopped() {
    _notificationService.showInfo(
      title: 'Scanning Stopped',
      message: 'Device scanning has been stopped',
    );
  }

  @override
  void onScanError(String error) {
    _notificationService.showError(
      title: 'Scan Error',
      message: 'Failed to start scanning: $error',
    );
  }

  @override
  void onStopScanError(String error) {
    _notificationService.showError(
      title: 'Stop Scan Error',
      message: 'Failed to stop scanning: $error',
    );
  }

  @override
  void onConnecting() {
    _notificationService.showInfo(
      title: 'Connecting',
      message: 'Attempting to connect to device...',
    );
  }

  @override
  void onConnected() {
    _notificationService.showSuccess(
      title: 'Connected',
      message: 'Successfully connected to device',
    );
  }

  @override
  void onConnectionError(String error) {
    _notificationService.showError(
      title: 'Connection Error',
      message: 'Failed to connect to device: $error',
    );
  }

  @override
  void onDisconnectError(String error) {
    _notificationService.showError(
      title: 'Disconnect Error',
      message: 'Failed to disconnect device: $error',
    );
  }

  @override
  void onDiscoveringServices() {
    _notificationService.showInfo(
      title: 'Discovering Services',
      message: 'Exploring device capabilities...',
    );
  }

  @override
  void onServicesFound(int count) {
    _notificationService.showSuccess(
      title: 'Services Found',
      message: 'Discovered $count service(s)',
    );
  }

  @override
  void onNoServicesFound() {
    _notificationService.showWarning(
      title: 'No Services',
      message: 'No GATT services found on device',
    );
  }

  @override
  void onServiceDiscoveryError(String error) {
    _notificationService.showError(
      title: 'Service Discovery Error',
      message: 'Failed to discover services: $error',
    );
  }

  @override
  void onEmptyCommand() {
    _notificationService.showWarning(
      title: 'Empty Command',
      message: 'Please enter a command to send',
    );
  }

  @override
  void onCommandError(String error) {
    _notificationService.showError(
      title: 'Command Error',
      message: 'Failed to send command: $error',
    );
  }

  @override
  void onDevicesCleared() {
    _notificationService.showInfo(
      title: 'Devices Cleared',
      message: 'Cleared device list',
    );
  }
}

/// Minimal implementation of BleNotificationDelegate that only shows errors.
/// This is the recommended default for production use to avoid notification spam.
///
/// Only notifies users about:
/// - Initialization failures
/// - Scan errors
/// - Connection errors
/// - Service discovery errors
/// - Command errors
///
/// Silently ignores:
/// - Success messages (Controller Ready, Connected, Services Found)
/// - Info messages (Scanning Started/Stopped, Connecting, Discovering Services)
/// - Non-critical warnings (No Services Found, Empty Command)
class MinimalBleNotificationDelegate implements BleNotificationDelegate {
  final NotificationServiceInterface _notificationService;

  const MinimalBleNotificationDelegate(this._notificationService);

  // Initialization - only show errors
  @override
  void onInitializeSuccess() {} // Silent - UI already shows connection state
  @override
  void onInitializeFailed() {
    _notificationService.showError(
      title: 'Initialization Failed',
      message: 'Failed to initialize BLE Controller',
    );
  }
  @override
  void onInitializeError(String error) {
    _notificationService.showError(
      title: 'Controller Error',
      message: 'Unexpected error during initialization: $error',
    );
  }

  // Scanning - only show errors
  @override
  void onScanStarted() {} // Silent - UI shows scanning indicator
  @override
  void onScanStopped() {} // Silent - UI shows scanning indicator
  @override
  void onScanError(String error) {
    _notificationService.showError(
      title: 'Scan Error',
      message: 'Failed to start scanning: $error',
    );
  }
  @override
  void onStopScanError(String error) {
    _notificationService.showError(
      title: 'Stop Scan Error',
      message: 'Failed to stop scanning: $error',
    );
  }

  // Connection - only show errors
  @override
  void onConnecting() {} // Silent - UI shows connecting state
  @override
  void onConnected() {} // Silent - UI shows connected state
  @override
  void onConnectionError(String error) {
    _notificationService.showError(
      title: 'Connection Failed',
      message: error,
    );
  }
  @override
  void onDisconnectError(String error) {
    _notificationService.showError(
      title: 'Disconnect Error',
      message: error,
    );
  }

  // Service discovery - only show errors
  @override
  void onDiscoveringServices() {} // Silent - internal operation
  @override
  void onServicesFound(int count) {} // Silent - internal operation
  @override
  void onNoServicesFound() {} // Silent - not an error, just no services
  @override
  void onServiceDiscoveryError(String error) {
    _notificationService.showError(
      title: 'Service Discovery Error',
      message: error,
    );
  }

  // Command - only show errors
  @override
  void onEmptyCommand() {} // Silent - input validation, not important
  @override
  void onCommandError(String error) {
    _notificationService.showError(
      title: 'Command Failed',
      message: error,
    );
  }

  // Device list - silent
  @override
  void onDevicesCleared() {} // Silent - UI reflects the change
}

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

/// Configurable implementation of BleNotificationDelegate that can change
/// behavior at runtime based on user preferences.
///
/// This is the recommended delegate for production use as it allows users
/// to control how many notifications they see without restarting the app.
class ConfigurableBleNotificationDelegate implements BleNotificationDelegate {
  final NotificationServiceInterface _notificationService;
  BleNotificationVerbosity _verbosity;

  ConfigurableBleNotificationDelegate(
    this._notificationService, {
    BleNotificationVerbosity verbosity = BleNotificationVerbosity.minimal,
  }) : _verbosity = verbosity;

  /// Get current verbosity level
  BleNotificationVerbosity get verbosity => _verbosity;

  /// Update verbosity level at runtime
  void setVerbosity(BleNotificationVerbosity verbosity) {
    _verbosity = verbosity;
  }

  // Helper methods to check what should be shown
  bool get _showInfo => _verbosity == BleNotificationVerbosity.verbose;
  bool get _showSuccess => _verbosity == BleNotificationVerbosity.verbose;
  bool get _showWarning => _verbosity == BleNotificationVerbosity.verbose ||
                           _verbosity == BleNotificationVerbosity.normal;
  bool get _showError => _verbosity != BleNotificationVerbosity.silent;

  // Initialization notifications
  @override
  void onInitializeSuccess() {
    if (_showSuccess) {
      _notificationService.showSuccess(
        title: 'Controller Ready',
        message: 'BLE Controller initialized successfully',
      );
    }
  }

  @override
  void onInitializeFailed() {
    if (_showError) {
      _notificationService.showError(
        title: 'Initialization Failed',
        message: 'Failed to initialize BLE Controller',
      );
    }
  }

  @override
  void onInitializeError(String error) {
    if (_showError) {
      _notificationService.showError(
        title: 'Controller Error',
        message: 'Unexpected error during initialization: $error',
      );
    }
  }

  // Scanning notifications
  @override
  void onScanStarted() {
    if (_showInfo) {
      _notificationService.showInfo(
        title: 'Scanning Started',
        message: 'Looking for BLE devices nearby...',
      );
    }
  }

  @override
  void onScanStopped() {
    if (_showInfo) {
      _notificationService.showInfo(
        title: 'Scanning Stopped',
        message: 'Device scanning has been stopped',
      );
    }
  }

  @override
  void onScanError(String error) {
    if (_showError) {
      _notificationService.showError(
        title: 'Scan Error',
        message: 'Failed to start scanning: $error',
      );
    }
  }

  @override
  void onStopScanError(String error) {
    if (_showError) {
      _notificationService.showError(
        title: 'Stop Scan Error',
        message: 'Failed to stop scanning: $error',
      );
    }
  }

  // Connection notifications
  @override
  void onConnecting() {
    if (_showInfo) {
      _notificationService.showInfo(
        title: 'Connecting',
        message: 'Attempting to connect to device...',
      );
    }
  }

  @override
  void onConnected() {
    if (_showSuccess) {
      _notificationService.showSuccess(
        title: 'Connected',
        message: 'Successfully connected to device',
      );
    }
  }

  @override
  void onConnectionError(String error) {
    if (_showError) {
      _notificationService.showError(
        title: 'Connection Failed',
        message: error,
      );
    }
  }

  @override
  void onDisconnectError(String error) {
    if (_showError) {
      _notificationService.showError(
        title: 'Disconnect Error',
        message: error,
      );
    }
  }

  // Service discovery notifications
  @override
  void onDiscoveringServices() {
    if (_showInfo) {
      _notificationService.showInfo(
        title: 'Discovering Services',
        message: 'Exploring device capabilities...',
      );
    }
  }

  @override
  void onServicesFound(int count) {
    if (_showSuccess) {
      _notificationService.showSuccess(
        title: 'Services Found',
        message: 'Discovered $count service(s)',
      );
    }
  }

  @override
  void onNoServicesFound() {
    if (_showWarning) {
      _notificationService.showWarning(
        title: 'No Services',
        message: 'No GATT services found on device',
      );
    }
  }

  @override
  void onServiceDiscoveryError(String error) {
    if (_showError) {
      _notificationService.showError(
        title: 'Service Discovery Error',
        message: error,
      );
    }
  }

  // Command notifications
  @override
  void onEmptyCommand() {
    if (_showWarning) {
      _notificationService.showWarning(
        title: 'Empty Command',
        message: 'Please enter a command to send',
      );
    }
  }

  @override
  void onCommandError(String error) {
    if (_showError) {
      _notificationService.showError(
        title: 'Command Failed',
        message: error,
      );
    }
  }

  // Device list notifications
  @override
  void onDevicesCleared() {
    if (_showInfo) {
      _notificationService.showInfo(
        title: 'Devices Cleared',
        message: 'Cleared device list',
      );
    }
  }
}

/// Silent implementation of BleNotificationDelegate that suppresses all notifications.
/// Useful for testing or background operations.
class SilentBleNotificationDelegate implements BleNotificationDelegate {
  const SilentBleNotificationDelegate();

  @override
  void onInitializeSuccess() {}
  @override
  void onInitializeFailed() {}
  @override
  void onInitializeError(String error) {}
  @override
  void onScanStarted() {}
  @override
  void onScanStopped() {}
  @override
  void onScanError(String error) {}
  @override
  void onStopScanError(String error) {}
  @override
  void onConnecting() {}
  @override
  void onConnected() {}
  @override
  void onConnectionError(String error) {}
  @override
  void onDisconnectError(String error) {}
  @override
  void onDiscoveringServices() {}
  @override
  void onServicesFound(int count) {}
  @override
  void onNoServicesFound() {}
  @override
  void onServiceDiscoveryError(String error) {}
  @override
  void onEmptyCommand() {}
  @override
  void onCommandError(String error) {}
  @override
  void onDevicesCleared() {}
}
