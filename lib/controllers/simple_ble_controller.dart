import 'dart:async';
import '../models/ble_device.dart';
import '../models/ble_service.dart';
import '../services/notification_service.dart' show NotificationModel;
import '../core/interfaces/ble_service_interface.dart';
import '../core/interfaces/notification_service_interface.dart';
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
  })  : _bleService = bleService,
        _notificationService = notificationService;

  final BleServiceInterface _bleService;
  final NotificationServiceInterface _notificationService;

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
        _notificationService.showSuccess(
          title: 'Controller Ready',
          message: 'BLE Controller initialized successfully',
        );
      } else {
        _notificationService.showError(
          title: 'Initialization Failed',
          message: 'Failed to initialize BLE Controller',
        );
      }
      return success;
    } catch (e) {
      _notificationService.showError(
        title: 'Controller Error',
        message: 'Unexpected error during initialization: $e',
      );
      return false;
    }
  }

  // Start scanning for devices
  @override
  Future<bool> startScanning({Duration? timeout}) async {
    try {
      _notificationService.showInfo(
        title: 'Scanning Started',
        message: 'Looking for BLE devices nearby...',
      );
      
      return await _bleService.startScanning(
        timeout: timeout ?? const Duration(seconds: 15),
      );
    } catch (e) {
      _notificationService.showError(
        title: 'Scan Error',
        message: 'Failed to start scanning: $e',
      );
      return false;
    }
  }

  // Stop scanning
  @override
  Future<void> stopScanning() async {
    try {
      await _bleService.stopScanning();
      _notificationService.showInfo(
        title: 'Scanning Stopped',
        message: 'Device scanning has been stopped',
      );
    } catch (e) {
      _notificationService.showError(
        title: 'Stop Scan Error',
        message: 'Failed to stop scanning: $e',
      );
    }
  }

  // Connect to a device
  @override
  Future<bool> connectToDevice(String deviceId) async {
    try {
      _notificationService.showInfo(
        title: 'Connecting',
        message: 'Attempting to connect to device...',
      );

      bool success = await _bleService.connectToDevice(deviceId);
      
      if (success) {
        // Automatically discover services after connection
        await discoverServices(deviceId);
      }
      
      return success;
    } catch (e) {
      _notificationService.showError(
        title: 'Connection Error',
        message: 'Failed to connect to device: $e',
      );
      return false;
    }
  }

  // Disconnect from current device
  @override
  Future<void> disconnectDevice() async {
    try {
      await _bleService.disconnectDevice();
    } catch (e) {
      _notificationService.showError(
        title: 'Disconnect Error',
        message: 'Failed to disconnect device: $e',
      );
    }
  }

  // Discover services for a connected device
  @override
  Future<List<BleServiceModel>> discoverServices(String deviceId) async {
    try {
      _notificationService.showInfo(
        title: 'Discovering Services',
        message: 'Exploring device capabilities...',
      );

      List<BleServiceModel> services = await _bleService.discoverServices(deviceId);
      
      if (services.isNotEmpty) {
        _notificationService.showSuccess(
          title: 'Services Found',
          message: 'Discovered ${services.length} service(s)',
        );
      } else {
        _notificationService.showWarning(
          title: 'No Services',
          message: 'No GATT services found on device',
        );
      }
      
      return services;
    } catch (e) {
      _notificationService.showError(
        title: 'Service Discovery Error',
        message: 'Failed to discover services: $e',
      );
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
    _notificationService.showInfo(
      title: 'Devices Cleared',
      message: 'Cleared device list',
    );
  }

  // Send text command to connected device
  @override
  Future<bool> sendCommand(String command) async {
    if (command.trim().isEmpty) {
      _notificationService.showWarning(
        title: 'Empty Command',
        message: 'Please enter a command to send',
      );
      return false;
    }

    try {
      return await _bleService.sendCommand(command.trim());
    } catch (e) {
      _notificationService.showError(
        title: 'Command Error',
        message: 'Failed to send command: $e',
      );
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