import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleManager {
  static final BleManager _instance = BleManager._internal();
  factory BleManager() => _instance;
  BleManager._internal();

  // Stream controllers for UI updates
  final StreamController<List<BluetoothDevice>> _scannedDevicesController = 
      StreamController<List<BluetoothDevice>>.broadcast();
  final StreamController<bool> _scanningController = 
      StreamController<bool>.broadcast();
  final StreamController<BluetoothDevice?> _connectedDeviceController = 
      StreamController<BluetoothDevice?>.broadcast();

  // Getters for streams
  Stream<List<BluetoothDevice>> get scannedDevicesStream => _scannedDevicesController.stream;
  Stream<bool> get scanningStream => _scanningController.stream;
  Stream<BluetoothDevice?> get connectedDeviceStream => _connectedDeviceController.stream;

  // Internal state
  final List<BluetoothDevice> _scannedDevices = [];
  BluetoothDevice? _connectedDevice;
  bool _isScanning = false;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;

  /// Initialize BLE manager
  Future<bool> initialize() async {
    try {
      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint("Bluetooth not supported by this device");
        return false;
      }

      // Request permissions
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        debugPrint("Required permissions not granted");
        return false;
      }

      // Listen to adapter state changes
      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        debugPrint("Bluetooth adapter state: $state");
        if (state != BluetoothAdapterState.on) {
          _stopScanning();
        }
      });

      return true;
    } catch (e) {
      debugPrint("Error initializing BLE manager: $e");
      return false;
    }
  }

  /// Request necessary permissions for BLE operations
  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((status) => 
        status == PermissionStatus.granted || status == PermissionStatus.permanentlyDenied);
  }

  /// Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() async {
    return await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
  }

  /// Turn on Bluetooth (this will show system dialog)
  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      debugPrint("Error turning on Bluetooth: $e");
    }
  }

  /// Start scanning for BLE devices
  Future<void> startScanning({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      if (_isScanning) {
        await stopScanning();
      }

      // Check if Bluetooth is enabled
      if (!await isBluetoothEnabled()) {
        debugPrint("Bluetooth is not enabled");
        return;
      }

      _scannedDevices.clear();
      _scannedDevicesController.add(_scannedDevices);
      
      _isScanning = true;
      _scanningController.add(true);

      // Listen to scan results
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (!_scannedDevices.any((device) => device.remoteId == result.device.remoteId)) {
            _scannedDevices.add(result.device);
          }
        }
        _scannedDevicesController.add(List.from(_scannedDevices));
      });

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      debugPrint("Started BLE scanning for ${timeout.inSeconds} seconds");

      // Auto stop after timeout
      Timer(timeout, () {
        if (_isScanning) {
          stopScanning();
        }
      });

    } catch (e) {
      debugPrint("Error starting scan: $e");
      _stopScanning();
    }
  }

  /// Stop scanning for BLE devices
  Future<void> stopScanning() async {
    await _stopScanning();
  }

  Future<void> _stopScanning() async {
    if (_isScanning) {
      try {
        await FlutterBluePlus.stopScan();
        _scanResultsSubscription?.cancel();
        _isScanning = false;
        _scanningController.add(false);
        debugPrint("Stopped BLE scanning");
      } catch (e) {
        debugPrint("Error stopping scan: $e");
      }
    }
  }

  /// Connect to a BLE device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _connectedDevice = device;
      _connectedDeviceController.add(device);
      
      debugPrint("Connected to device: ${device.platformName}");
      
      // Listen to connection state changes
      device.connectionState.listen((state) {
        debugPrint("Connection state: $state");
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
          _connectedDeviceController.add(null);
        }
      });

      return true;
    } catch (e) {
      debugPrint("Error connecting to device: $e");
      return false;
    }
  }

  /// Disconnect from current device
  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
        _connectedDevice = null;
        _connectedDeviceController.add(null);
        debugPrint("Disconnected from device");
      } catch (e) {
        debugPrint("Error disconnecting device: $e");
      }
    }
  }

  /// Get GATT services from connected device
  Future<List<BluetoothService>> getServices() async {
    if (_connectedDevice == null) {
      debugPrint("No device connected");
      return [];
    }

    try {
      return await _connectedDevice!.discoverServices();
    } catch (e) {
      debugPrint("Error discovering services: $e");
      return [];
    }
  }

  /// Read characteristic value
  Future<List<int>?> readCharacteristic(BluetoothCharacteristic characteristic) async {
    try {
      return await characteristic.read();
    } catch (e) {
      debugPrint("Error reading characteristic: $e");
      return null;
    }
  }

  /// Write to characteristic
  Future<bool> writeCharacteristic(BluetoothCharacteristic characteristic, List<int> value) async {
    try {
      await characteristic.write(value);
      return true;
    } catch (e) {
      debugPrint("Error writing characteristic: $e");
      return false;
    }
  }

  /// Subscribe to characteristic notifications
  Future<bool> subscribeToCharacteristic(BluetoothCharacteristic characteristic) async {
    try {
      await characteristic.setNotifyValue(true);
      return true;
    } catch (e) {
      debugPrint("Error subscribing to characteristic: $e");
      return false;
    }
  }

  /// Get current connected device
  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Get scanning state
  bool get isScanning => _isScanning;

  /// Get scanned devices list
  List<BluetoothDevice> get scannedDevices => List.from(_scannedDevices);

  /// Dispose resources
  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    _scannedDevicesController.close();
    _scanningController.close();
    _connectedDeviceController.close();
  }
}