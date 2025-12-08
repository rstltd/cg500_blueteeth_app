import 'dart:async';
import 'package:cg500_blueteeth_app/controllers/ble_controller_interface.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';

/// A mock implementation of BLE controller for testing widgets
/// that depend on SimpleBleController's streams.
///
/// This mock provides controllable StreamControllers that allow tests
/// to simulate various BLE states without requiring actual hardware.
class MockBleController implements BleControllerInterface {
  // Stream controllers for testing
  final StreamController<List<BleDeviceModel>> _devicesController =
      StreamController<List<BleDeviceModel>>.broadcast();
  final StreamController<bool> _scanningController =
      StreamController<bool>.broadcast();
  final StreamController<BleDeviceModel?> _connectedDeviceController =
      StreamController<BleDeviceModel?>.broadcast();
  final StreamController<String> _commandResponseController =
      StreamController<String>.broadcast();
  final StreamController<NotificationModel> _notificationController =
      StreamController<NotificationModel>.broadcast();

  // Public streams - same interface as SimpleBleController
  @override
  Stream<List<BleDeviceModel>> get devicesStream => _devicesController.stream;
  @override
  Stream<bool> get scanningStream => _scanningController.stream;
  @override
  Stream<BleDeviceModel?> get connectedDeviceStream => _connectedDeviceController.stream;
  @override
  Stream<String> get commandResponseStream => _commandResponseController.stream;
  @override
  Stream<NotificationModel> get notificationStream => _notificationController.stream;

  // Internal state
  List<BleDeviceModel> _devices = [];
  bool _isScanning = false;
  BleDeviceModel? _connectedDevice;
  bool _isInitialized = false;

  // Configurable behavior for testing
  bool _shouldSendCommandSucceed = true;
  bool _shouldConnectSucceed = true;
  Duration _commandDelay = Duration.zero;
  final List<String> _sentCommands = [];

  // Test inspection getters
  List<String> get sentCommands => List.unmodifiable(_sentCommands);
  int get sendCommandCallCount => _sentCommands.length;

  /// Configure send command behavior
  void configureSendCommand({
    bool succeed = true,
    Duration delay = Duration.zero,
  }) {
    _shouldSendCommandSucceed = succeed;
    _commandDelay = delay;
  }

  /// Configure connect behavior
  void configureConnect({bool succeed = true}) {
    _shouldConnectSucceed = succeed;
  }

  /// Simulate a connected device directly
  void simulateConnected(BleDeviceModel device) {
    _connectedDevice = device;
    _connectedDeviceController.add(device);
  }

  /// Simulate disconnection
  void simulateDisconnected() {
    _connectedDevice = null;
    _connectedDeviceController.add(null);
  }

  /// Reset all mock state
  void reset() {
    _devices = [];
    _isScanning = false;
    _connectedDevice = null;
    _isInitialized = false;
    _shouldSendCommandSucceed = true;
    _shouldConnectSucceed = true;
    _commandDelay = Duration.zero;
    _sentCommands.clear();
  }

  // Getters - same interface as SimpleBleController
  @override
  bool get isScanning => _isScanning;
  @override
  BleDeviceModel? get connectedDevice => _connectedDevice;
  @override
  List<BleDeviceModel> get scannedDevices => List.unmodifiable(_devices);
  @override
  bool get isInitialized => _isInitialized;

  // ============== Test Control Methods ==============

  /// Emit a list of devices to the stream
  void emitDevices(List<BleDeviceModel> devices) {
    _devices = devices;
    _devicesController.add(devices);
  }

  /// Emit scanning state to the stream
  void emitScanning(bool isScanning) {
    _isScanning = isScanning;
    _scanningController.add(isScanning);
  }

  /// Emit connected device to the stream
  void emitConnectedDevice(BleDeviceModel? device) {
    _connectedDevice = device;
    _connectedDeviceController.add(device);
  }

  /// Emit a command response
  void emitCommandResponse(String response) {
    _commandResponseController.add(response);
  }

  /// Emit a notification
  void emitNotification(NotificationModel notification) {
    _notificationController.add(notification);
  }

  // ============== Mock Methods (same interface as SimpleBleController) ==============

  /// Initialize the mock controller
  @override
  Future<bool> initialize() async {
    _isInitialized = true;
    return true;
  }

  /// Start scanning for devices
  @override
  Future<bool> startScanning({Duration? timeout}) async {
    _isScanning = true;
    _scanningController.add(true);
    return true;
  }

  /// Stop scanning
  @override
  Future<void> stopScanning() async {
    _isScanning = false;
    _scanningController.add(false);
  }

  /// Connect to a device
  @override
  Future<bool> connectToDevice(String deviceId) async {
    if (!_shouldConnectSucceed) {
      return false;
    }
    final device = _devices.firstWhere(
      (d) => d.id == deviceId,
      orElse: () => BleDeviceModel(
        id: deviceId,
        name: 'Mock Device',
        displayName: 'Mock Device',
      ),
    );
    _connectedDevice = device;
    _connectedDeviceController.add(device);
    return true;
  }

  /// Disconnect from current device
  @override
  Future<void> disconnectDevice() async {
    _connectedDevice = null;
    _connectedDeviceController.add(null);
  }

  /// Discover services
  @override
  Future<List<BleServiceModel>> discoverServices(String deviceId) async {
    return [];
  }

  /// Send command
  @override
  Future<bool> sendCommand(String command) async {
    _sentCommands.add(command);

    if (_commandDelay > Duration.zero) {
      await Future.delayed(_commandDelay);
    }

    if (_shouldSendCommandSucceed) {
      _commandResponseController.add('Response to: $command');
    }
    return _shouldSendCommandSucceed;
  }

  // Configurable command info for testing
  bool _hasCommandChannel = true;
  bool _hasResponseChannel = true;
  int _mtu = 247;

  /// Configure command info for testing
  void configureCommandInfo({
    bool hasCommandChannel = true,
    bool hasResponseChannel = true,
    int mtu = 247,
  }) {
    _hasCommandChannel = hasCommandChannel;
    _hasResponseChannel = hasResponseChannel;
    _mtu = mtu;
  }

  /// Get command info
  @override
  Map<String, dynamic> getCommandInfo() {
    return {
      'txCharacteristic': 'mock-tx',
      'rxCharacteristic': 'mock-rx',
      'connected': _connectedDevice != null,
      'hasCommandChannel': _hasCommandChannel,
      'hasResponseChannel': _hasResponseChannel,
      'mtu': _mtu,
    };
  }

  /// Clear devices
  @override
  void clearDevices() {
    _devices = [];
    _devicesController.add([]);
  }

  /// Dispose resources
  @override
  void dispose() {
    _devicesController.close();
    _scanningController.close();
    _connectedDeviceController.close();
    _commandResponseController.close();
    _notificationController.close();
  }
}

/// Helper function to create test devices
BleDeviceModel createTestDevice({
  String id = 'test-device-1',
  String name = 'Test Device',
  String? displayName,
  int rssi = -50,
  bool isFavorite = false,
  DateTime? lastSeen,
  DateTime? connectedAt,
  List<BleServiceModel>? services,
  BleConnectionState connectionState = BleConnectionState.disconnected,
}) {
  return BleDeviceModel(
    id: id,
    name: name,
    displayName: displayName ?? (name.isNotEmpty ? name : 'Unknown Device'),
    rssi: rssi,
    isFavorite: isFavorite,
    lastSeen: lastSeen,
    connectedAt: connectedAt,
    services: services ?? const [],
    connectionState: connectionState,
  );
}
