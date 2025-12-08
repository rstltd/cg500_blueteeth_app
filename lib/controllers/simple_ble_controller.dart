import 'dart:async';
import '../models/ble_device.dart';
import '../models/ble_service.dart';
import '../services/notification_service.dart' show NotificationModel;
import '../core/interfaces/ble_service_interface.dart';
import '../core/interfaces/notification_service_interface.dart';
import '../core/interfaces/ble_notification_delegate.dart';
import 'ble_controller_interface.dart';

/// Simple BLE Controller demonstrating the MVC architecture.
///
/// This is a simplified version showing how Controllers coordinate
/// between Services and Views in the new architecture.
/// Supports dependency injection for improved testability.
///
/// Use [SimpleBleController.withDependencies()] constructor and register via
/// service locator for production use.
class SimpleBleController implements BleControllerInterface {
  /// Named constructor for dependency injection.
  /// Use this when creating instances via the service locator.
  SimpleBleController.withDependencies({
    required BleServiceInterface bleService,
    required NotificationServiceInterface notificationService,
    BleNotificationDelegate? notificationDelegate,
  })  : _bleService = bleService,
        _notificationService = notificationService,
        _notificationDelegate = notificationDelegate ??
            ConfigurableBleNotificationDelegate(notificationService);

  final BleServiceInterface _bleService;
  final NotificationServiceInterface _notificationService;
  final BleNotificationDelegate _notificationDelegate;

  /// Getter for notification delegate (for testing and configuration)
  BleNotificationDelegate get notificationDelegate => _notificationDelegate;

  /// Update notification verbosity at runtime.
  /// Only works if using ConfigurableBleNotificationDelegate.
  @override
  void setNotificationVerbosity(BleNotificationVerbosity verbosity) {
    final delegate = _notificationDelegate;
    if (delegate is ConfigurableBleNotificationDelegate) {
      delegate.setVerbosity(verbosity);
    }
  }

  /// Get current notification verbosity.
  /// Returns null if not using ConfigurableBleNotificationDelegate.
  @override
  BleNotificationVerbosity? get notificationVerbosity {
    final delegate = _notificationDelegate;
    if (delegate is ConfigurableBleNotificationDelegate) {
      return delegate.verbosity;
    }
    return null;
  }

  // Expose service streams for UI consumption
  @override
  Stream<List<BleDeviceModel>> get devicesStream => _bleService.devicesStream;
  @override
  Stream<bool> get scanningStream => _bleService.scanningStream;
  @override
  Stream<BleDeviceModel?> get connectedDeviceStream => _bleService.connectedDeviceStream;
  @override
  Stream<String> get commandResponseStream => _bleService.commandResponseStream;

  // Expose notification stream for UI
  @override
  Stream<NotificationModel> get notificationStream => _notificationService.notifications;

  // Initialize the controller and underlying services
  @override
  Future<bool> initialize() async {
    try {
      bool success = await _bleService.initialize();
      if (success) {
        _notificationDelegate.onInitializeSuccess();
      } else {
        _notificationDelegate.onInitializeFailed();
      }
      return success;
    } catch (e) {
      _notificationDelegate.onInitializeError(e.toString());
      return false;
    }
  }

  // Start scanning for devices
  @override
  Future<bool> startScanning({Duration? timeout}) async {
    try {
      _notificationDelegate.onScanStarted();

      return await _bleService.startScanning(
        timeout: timeout ?? const Duration(seconds: 15),
      );
    } catch (e) {
      _notificationDelegate.onScanError(e.toString());
      return false;
    }
  }

  // Stop scanning
  @override
  Future<void> stopScanning() async {
    try {
      await _bleService.stopScanning();
      _notificationDelegate.onScanStopped();
    } catch (e) {
      _notificationDelegate.onStopScanError(e.toString());
    }
  }

  // Connect to a device
  @override
  Future<bool> connectToDevice(String deviceId) async {
    try {
      _notificationDelegate.onConnecting();

      bool success = await _bleService.connectToDevice(deviceId);

      if (success) {
        // Automatically discover services after connection
        await discoverServices(deviceId);
      }

      return success;
    } catch (e) {
      _notificationDelegate.onConnectionError(e.toString());
      return false;
    }
  }

  // Disconnect from current device
  @override
  Future<void> disconnectDevice() async {
    try {
      await _bleService.disconnectDevice();
    } catch (e) {
      _notificationDelegate.onDisconnectError(e.toString());
    }
  }

  // Discover services for a connected device
  @override
  Future<List<BleServiceModel>> discoverServices(String deviceId) async {
    try {
      _notificationDelegate.onDiscoveringServices();

      List<BleServiceModel> services =
          await _bleService.discoverServices(deviceId);

      if (services.isNotEmpty) {
        _notificationDelegate.onServicesFound(services.length);
      } else {
        _notificationDelegate.onNoServicesFound();
      }

      return services;
    } catch (e) {
      _notificationDelegate.onServiceDiscoveryError(e.toString());
      return [];
    }
  }

  // Get current state information
  @override
  bool get isScanning => _bleService.isScanning;
  @override
  BleDeviceModel? get connectedDevice => _bleService.connectedDevice;
  @override
  List<BleDeviceModel> get scannedDevices => _bleService.scannedDevices;
  @override
  bool get isInitialized => _bleService.isInitialized;

  // Clear scanned devices list
  @override
  void clearDevices() {
    _bleService.clearScannedDevices();
    _notificationDelegate.onDevicesCleared();
  }

  // Send text command to connected device
  @override
  Future<bool> sendCommand(String command) async {
    if (command.trim().isEmpty) {
      _notificationDelegate.onEmptyCommand();
      return false;
    }

    try {
      return await _bleService.sendCommand(command.trim());
    } catch (e) {
      _notificationDelegate.onCommandError(e.toString());
      return false;
    }
  }

  // Get command communication information
  @override
  Map<String, dynamic> getCommandInfo() {
    return _bleService.getCommandInfo();
  }

  // Dispose resources
  @override
  void dispose() {
    _bleService.dispose();
    _notificationService.dispose();
  }
}