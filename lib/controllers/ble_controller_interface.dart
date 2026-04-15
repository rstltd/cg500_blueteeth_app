import 'dart:async';
import '../models/ble_device.dart';
import '../models/ble_service.dart';
import '../services/notification_service.dart';
import '../core/interfaces/ble_notification_delegate.dart';

/// Abstract interface for BLE controller
/// Allows dependency injection for testing widgets
abstract class BleControllerInterface {
  // Streams
  Stream<List<BleDeviceModel>> get devicesStream;
  Stream<bool> get scanningStream;
  Stream<BleDeviceModel?> get connectedDeviceStream;
  Stream<String> get commandResponseStream;
  Stream<NotificationModel> get notificationStream;

  /// Emits the current BLE adapter on/off state whenever it changes. Used by
  /// ViewModels to auto-clear a BLE_DISABLED blocking error screen when the
  /// user re-enables Bluetooth from the system settings.
  Stream<bool> get adapterOnStream;

  // State getters
  bool get isScanning;
  BleDeviceModel? get connectedDevice;
  List<BleDeviceModel> get scannedDevices;
  bool get isInitialized;

  // Notification verbosity (optional - may return null if not configurable)
  BleNotificationVerbosity? get notificationVerbosity;

  // Methods
  Future<bool> initialize();
  Future<bool> startScanning({Duration? timeout});
  Future<void> stopScanning();
  Future<bool> connectToDevice(String deviceId);
  Future<void> disconnectDevice();
  Future<List<BleServiceModel>> discoverServices(String deviceId);
  Future<bool> sendCommand(String command);
  Map<String, dynamic> getCommandInfo();
  void clearDevices();
  void dispose();

  // Notification configuration
  void setNotificationVerbosity(BleNotificationVerbosity verbosity);
}
