import 'dart:async';
import '../services/ble_service.dart';
import '../services/smart_notification_service.dart';
import '../services/notification_service.dart'; // For NotificationModel
import '../models/ble_device.dart';
import '../models/ble_service.dart';

/// Simple BLE Controller demonstrating the MVC architecture
/// This is a simplified version showing how Controllers coordinate
/// between Services and Views in the new architecture
class SimpleBleController {
  static final SimpleBleController _instance = SimpleBleController._internal();
  factory SimpleBleController() => _instance;
  SimpleBleController._internal();

  final BleService _bleService = BleService();
  final SmartNotificationService _notificationService = SmartNotificationService();

  // Expose service streams for UI consumption
  Stream<List<BleDeviceModel>> get devicesStream => _bleService.devicesStream;
  Stream<bool> get scanningStream => _bleService.scanningStream;
  Stream<BleDeviceModel?> get connectedDeviceStream => _bleService.connectedDeviceStream;
  Stream<String> get commandResponseStream => _bleService.commandResponseStream;

  // Expose notification stream for UI
  Stream<NotificationModel> get notificationStream => _notificationService.notifications;

  // Initialize the controller and underlying services
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
  bool get isScanning => _bleService.isScanning;
  BleDeviceModel? get connectedDevice => _bleService.connectedDevice;
  List<BleDeviceModel> get scannedDevices => _bleService.scannedDevices;
  bool get isInitialized => _bleService.isInitialized;

  // Clear scanned devices list
  void clearDevices() {
    _bleService.clearScannedDevices();
    _notificationService.showInfo(
      title: 'Devices Cleared',
      message: 'Cleared device list',
    );
  }

  // Send text command to connected device
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
  Map<String, dynamic> getCommandInfo() {
    return _bleService.getCommandInfo();
  }

  // Dispose resources
  void dispose() {
    _bleService.dispose();
    _notificationService.dispose();
  }
}