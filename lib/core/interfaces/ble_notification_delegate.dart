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
