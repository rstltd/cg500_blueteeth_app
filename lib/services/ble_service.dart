import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_device.dart';
import '../models/ble_service.dart';
import '../models/connection_state.dart';
import '../utils/logger.dart';
import 'permission_service.dart';
import 'smart_notification_service.dart';
// import 'error_handling_service.dart'; // Reserved for future use

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  final PermissionService _permissionService = PermissionService();
  final SmartNotificationService _notificationService = SmartNotificationService();
  // final ErrorHandlingService _errorHandlingService = ErrorHandlingService(); // Reserved for future use

  final StreamController<List<BleDeviceModel>> _devicesController = 
      StreamController<List<BleDeviceModel>>.broadcast();
  final StreamController<bool> _scanningController = 
      StreamController<bool>.broadcast();
  final StreamController<BleDeviceModel?> _connectedDeviceController = 
      StreamController<BleDeviceModel?>.broadcast();
  final StreamController<String> _commandResponseController = 
      StreamController<String>.broadcast();

  Stream<List<BleDeviceModel>> get devicesStream => _devicesController.stream;
  Stream<bool> get scanningStream => _scanningController.stream;
  Stream<BleDeviceModel?> get connectedDeviceStream => _connectedDeviceController.stream;
  Stream<String> get commandResponseStream => _commandResponseController.stream;

  final Map<String, BleDeviceModel> _scannedDevices = {};
  final Map<String, BluetoothDevice> _bluetoothDevicesCache = {};
  BleDeviceModel? _connectedDevice;
  bool _isScanning = false;
  bool _isInitialized = false;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  
  // Command communication properties
  // BluetoothDevice? _connectedBluetoothDevice; // Unused - using _bluetoothDevicesCache instead
  BluetoothCharacteristic? _commandCharacteristic;
  BluetoothCharacteristic? _responseCharacteristic;
  StreamSubscription<List<int>>? _responseSubscription;
  static const int targetMtu = 517;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (await FlutterBluePlus.isSupported == false) {
        _notificationService.showError(
          title: 'Bluetooth Not Supported',
          message: 'This device does not support Bluetooth',
        );
        return false;
      }

      bool hasPermissions = await _permissionService.hasBluetoothPermissions();
      if (!hasPermissions) {
        hasPermissions = await _permissionService.requestBluetoothPermissions();
        if (!hasPermissions) {
          _notificationService.showError(
            title: 'Permissions Required',
            message: 'Bluetooth permissions are required to use this app',
          );
          return false;
        }
      }

      _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
        Logger.ble('Bluetooth adapter state: $state');
        if (state != BluetoothAdapterState.on) {
          stopScanning();
        }
      });

      _isInitialized = true;
      // Only show initialization success on first run
      _notificationService.showSuccess(
        title: 'Bluetooth Ready',
        message: 'BLE service initialized successfully',
      );
      return true;

    } catch (e) {
      Logger.error('Failed to initialize BLE service', error: e);
      _notificationService.showError(
        title: 'Initialization Failed',
        message: 'Failed to initialize BLE service: $e',
      );
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    return await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
  }

  Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      Logger.error('Error turning on Bluetooth', error: e);
      _notificationService.showError(
        title: 'Bluetooth Error',
        message: 'Could not turn on Bluetooth automatically',
      );
    }
  }

  Future<bool> startScanning({Duration timeout = const Duration(seconds: 15)}) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isScanning) {
      await stopScanning();
    }

    if (!await isBluetoothEnabled()) {
      _notificationService.showScanningStatus(
        title: 'Bluetooth Disabled',
        message: 'Please enable Bluetooth to scan for devices',
        isScanning: false,
      );
      await turnOnBluetooth();
      return false;
    }

    try {
      _isScanning = true;
      _scanningController.add(true);

      _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
        (results) => _handleScanResults(results),
      );

      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      Logger.ble('Started BLE scanning for ${timeout.inSeconds} seconds');

      Timer(timeout, () {
        if (_isScanning) {
          stopScanning();
        }
      });

      return true;

    } catch (e) {
      Logger.error('Error starting scan', error: e);
      _notificationService.showError(
        title: 'Scan Failed',
        message: 'Failed to start scanning: $e',
      );
      await _stopScanningInternal();
      return false;
    }
  }

  void _handleScanResults(List<ScanResult> results) {
    for (ScanResult result in results) {
      String deviceId = result.device.remoteId.toString();
      
      // Skip devices without a proper name to keep the UI clean
      if (result.device.platformName.isEmpty) {
        continue;
      }
      
      // Cache the BluetoothDevice for later connection
      _bluetoothDevicesCache[deviceId] = result.device;
      
      BleDeviceModel existingDevice = _scannedDevices[deviceId] ??
          BleDeviceModel.fromBluetoothDevice(result.device, rssi: result.rssi);
          
      BleDeviceModel updatedDevice = existingDevice.updateRssi(result.rssi);
      _scannedDevices[deviceId] = updatedDevice;
    }
    
    _devicesController.add(_scannedDevices.values.toList());
  }

  Future<void> stopScanning() async {
    await _stopScanningInternal();
  }

  Future<void> _stopScanningInternal() async {
    if (_isScanning) {
      try {
        await FlutterBluePlus.stopScan();
        await _scanResultsSubscription?.cancel();
        _isScanning = false;
        _scanningController.add(false);
        Logger.ble('Stopped BLE scanning');
      } catch (e) {
        Logger.error('Error stopping scan', error: e);
      }
    }
  }

  Future<bool> connectToDevice(String deviceId) async {
    BleDeviceModel? device = _scannedDevices[deviceId];
    if (device == null) {
      _notificationService.showError(
        title: 'Device Not Found',
        message: 'Cannot find device with ID: $deviceId',
      );
      return false;
    }

    if (_connectedDevice != null && _connectedDevice!.connectionState.isConnected) {
      await disconnectDevice();
    }

    try {
      // Update connection state to connecting
      BleDeviceModel connectingDevice = device.updateConnectionState(BleConnectionState.connecting);
      _scannedDevices[deviceId] = connectingDevice;
      _devicesController.add(_scannedDevices.values.toList());
      _connectedDeviceController.add(connectingDevice);

      // Find the actual BluetoothDevice
      BluetoothDevice? bluetoothDevice = await _findBluetoothDevice(deviceId);
      if (bluetoothDevice == null) {
        throw Exception('Bluetooth device not found');
      }

      await bluetoothDevice.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // Update cache to ensure we have the most recent reference
      _bluetoothDevicesCache[deviceId] = bluetoothDevice;

      // Set MTU to 517 as required by device manufacturer
      try {
        int mtu = await bluetoothDevice.requestMtu(targetMtu);
        Logger.ble('MTU set to: $mtu (requested: $targetMtu)');
        // Silent operation - MTU configuration is internal
      } catch (e) {
        Logger.error('Failed to set MTU', error: e);
        _notificationService.showWarning(
          title: 'MTU Warning',
          message: 'Could not set MTU to $targetMtu: $e',
        );
      }

      // Update connection state to connected
      BleDeviceModel connectedDevice = connectingDevice.updateConnectionState(BleConnectionState.connected);
      _scannedDevices[deviceId] = connectedDevice;
      _connectedDevice = connectedDevice;
      _devicesController.add(_scannedDevices.values.toList());
      _connectedDeviceController.add(connectedDevice);
      
      Logger.connection('Connection successful: ${connectedDevice.displayName}');
      Logger.connection('Connected device set: ${_connectedDevice?.displayName}');

      // Listen to connection state changes (but avoid immediate override)
      Timer(const Duration(milliseconds: 1000), () {
        bluetoothDevice.connectionState.listen((state) {
          Logger.connection('Connection state change: $deviceId -> $state');
          _handleConnectionStateChange(deviceId, state);
        });
      });

      _notificationService.showConnectionStatus(
        title: 'Connected',
        message: 'Successfully connected to ${device.displayName}',
        isConnected: true,
      );

      return true;

    } catch (e) {
      Logger.error('Error connecting to device', error: e);
      
      // Update connection state back to disconnected
      BleDeviceModel failedDevice = device.updateConnectionState(BleConnectionState.disconnected);
      _scannedDevices[deviceId] = failedDevice;
      _devicesController.add(_scannedDevices.values.toList());
      _connectedDeviceController.add(null);

      _notificationService.showError(
        title: 'Connection Failed',
        message: 'Failed to connect to ${device.displayName}: $e',
      );
      
      return false;
    }
  }

  void _handleConnectionStateChange(String deviceId, BluetoothConnectionState state) {
    Logger.connection('_handleConnectionStateChange: $deviceId -> $state');
    
    BleConnectionState connectionState;
    switch (state) {
      case BluetoothConnectionState.connected:
        connectionState = BleConnectionState.connected;
        break;
      case BluetoothConnectionState.disconnected:
        connectionState = BleConnectionState.disconnected;
        break;
      // Ignore deprecated connecting and disconnecting states
      default:
        return; // Don't update for deprecated states
    }

    BleDeviceModel? device = _scannedDevices[deviceId];
    if (device != null) {
      BleDeviceModel updatedDevice = device.updateConnectionState(connectionState);
      _scannedDevices[deviceId] = updatedDevice;
      _devicesController.add(_scannedDevices.values.toList());
      
      Logger.connection('Updated device state: ${updatedDevice.connectionState}');

      if (connectionState.isConnected) {
        _connectedDevice = updatedDevice;
        _connectedDeviceController.add(updatedDevice);
        Logger.connection('Set connected device: ${updatedDevice.displayName}');
      } else if (connectionState.isDisconnected) {
        if (_connectedDevice?.id == deviceId) {
          _connectedDevice = null;
          _connectedDeviceController.add(null);
          Logger.connection('Cleared connected device');
        }
      }
    } else {
      Logger.debug('Device not found in scanned devices: $deviceId');
    }
  }

  Future<BluetoothDevice?> _findBluetoothDevice(String deviceId) async {
    // First check if we have it in our cache from scanning
    if (_bluetoothDevicesCache.containsKey(deviceId)) {
      return _bluetoothDevicesCache[deviceId];
    }

    // Fallback: check connected devices
    List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
    for (BluetoothDevice device in connectedDevices) {
      if (device.remoteId.toString() == deviceId) {
        return device;
      }
    }

    Logger.debug('BluetoothDevice not found in cache or connected devices: $deviceId');
    return null;
  }

  Future<void> disconnectDevice() async {
    if (_connectedDevice == null) return;

    try {
      String deviceId = _connectedDevice!.id;
      
      // Update connection state to disconnecting
      BleDeviceModel disconnectingDevice = _connectedDevice!.updateConnectionState(BleConnectionState.disconnecting);
      _scannedDevices[deviceId] = disconnectingDevice;
      _devicesController.add(_scannedDevices.values.toList());
      _connectedDeviceController.add(disconnectingDevice);

      // Find and disconnect the actual BluetoothDevice
      BluetoothDevice? bluetoothDevice = await _findBluetoothDevice(deviceId);
      if (bluetoothDevice != null) {
        await bluetoothDevice.disconnect();
      }

      // Update connection state to disconnected
      BleDeviceModel disconnectedDevice = disconnectingDevice.updateConnectionState(BleConnectionState.disconnected);
      _scannedDevices[deviceId] = disconnectedDevice;
      _devicesController.add(_scannedDevices.values.toList());
      
      _connectedDevice = null;
      _connectedDeviceController.add(null);
      
      // Clean up command communication
      _cleanupCommandCharacteristics();

      _notificationService.showConnectionStatus(
        title: 'Disconnected',
        message: 'Disconnected from device',
        isConnected: false,
      );

    } catch (e) {
      Logger.error('Error disconnecting device', error: e);
      _notificationService.showError(
        title: 'Disconnect Failed',
        message: 'Failed to disconnect device: $e',
      );
    }
  }

  Future<List<BleServiceModel>> discoverServices(String deviceId) async {
    BleDeviceModel? device = _scannedDevices[deviceId];
    if (device == null || !device.connectionState.isConnected) {
      _notificationService.showError(
        title: 'Device Not Connected',
        message: 'Device must be connected to discover services',
      );
      return [];
    }

    try {
      BluetoothDevice? bluetoothDevice = await _findBluetoothDevice(deviceId);
      if (bluetoothDevice == null) {
        throw Exception('Bluetooth device not found');
      }

      List<BluetoothService> services = await bluetoothDevice.discoverServices();
      List<BleServiceModel> serviceModels = services
          .map((service) => BleServiceModel.fromBluetoothService(service))
          .toList();

      // Setup command communication characteristics
      await _setupCommandCharacteristics(services);

      // Update device with services
      BleDeviceModel updatedDevice = device.updateServices(serviceModels);
      _scannedDevices[deviceId] = updatedDevice;
      _devicesController.add(_scannedDevices.values.toList());

      if (_connectedDevice?.id == deviceId) {
        _connectedDevice = updatedDevice;
        _connectedDeviceController.add(updatedDevice);
      }

      return serviceModels;

    } catch (e) {
      Logger.error('Error discovering services', error: e);
      _notificationService.showError(
        title: 'Service Discovery Failed',
        message: 'Failed to discover services: $e',
      );
      return [];
    }
  }

  // Getters
  List<BleDeviceModel> get scannedDevices => _scannedDevices.values.toList();
  BleDeviceModel? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get isInitialized => _isInitialized;

  void clearScannedDevices() {
    _scannedDevices.clear();
    _bluetoothDevicesCache.clear();
    _devicesController.add([]);
  }

  // Setup command communication characteristics for Nordic UART Service
  Future<void> _setupCommandCharacteristics(List<BluetoothService> services) async {
    try {
      // Nordic UART Service UUIDs
      const String nordicUartServiceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
      const String nordicUartRxUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e'; // RX - phone writes to device
      const String nordicUartTxUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // TX - device notifies phone
      
      Logger.ble('Looking for Nordic UART Service...');
      
      for (BluetoothService service in services) {
        String serviceUuid = service.uuid.toString().toLowerCase();
        Logger.ble('Service found: $serviceUuid');
        
        // Look specifically for Nordic UART Service
        if (serviceUuid == nordicUartServiceUuid) {
          Logger.ble('Nordic UART Service found!');
          
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toLowerCase();
            Logger.ble('Characteristic: $charUuid, Properties: ${characteristic.properties}');
            
            // RX Characteristic (6e400002) - phone writes commands to device
            if (charUuid == nordicUartRxUuid && characteristic.properties.write) {
              _commandCharacteristic = characteristic;
              Logger.ble('Nordic UART RX characteristic found (command channel): $charUuid');
            }
            
            // TX Characteristic (6e400003) - device sends notifications to phone
            if (charUuid == nordicUartTxUuid && characteristic.properties.notify) {
              _responseCharacteristic = characteristic;
              
              // Set TX characteristic to 01-00 (enable notifications)
              try {
                Logger.ble('Attempting to enable notifications on TX characteristic: $charUuid');
                await characteristic.setNotifyValue(true);
                Logger.ble('Nordic UART TX notifications enabled successfully');
                
                // Verify the CCC descriptor was set to 01-00
                for (BluetoothDescriptor descriptor in characteristic.descriptors) {
                  Logger.ble('Descriptor found: ${descriptor.uuid}');
                  if (descriptor.uuid.toString().toLowerCase() == '00002902-0000-1000-8000-00805f9b34fb') {
                    List<int> value = await descriptor.read();
                    Logger.ble('CCC descriptor value: ${value.map((e) => e.toRadixString(16).padLeft(2, '0')).join('-')}');
                  }
                }
                
                // Subscribe to responses
                _responseSubscription = characteristic.lastValueStream.listen((data) {
                  String response = utf8.decode(data);
                  Logger.command('Received Nordic UART response: $response');
                  _commandResponseController.add(response);
                }, onError: (error) {
                  Logger.error('Error in response stream', error: error);
                });
                
                Logger.ble('Nordic UART TX characteristic setup complete: $charUuid');
              } catch (e) {
                Logger.error('Error enabling TX notifications', error: e);
              }
            }
          }
          break; // Found Nordic UART Service, no need to check other services
        }
      }

      // Fallback: look for any writable and notifiable characteristics if Nordic UART not found
      if (_commandCharacteristic == null || _responseCharacteristic == null) {
        Logger.ble('Nordic UART Service not found, looking for generic characteristics...');
        
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            // Look for command characteristic (writable)
            if (characteristic.properties.write && _commandCharacteristic == null) {
              _commandCharacteristic = characteristic;
              Logger.ble('Generic command characteristic found: ${characteristic.uuid}');
            }
            
            // Look for response characteristic (notifiable)
            if (characteristic.properties.notify && _responseCharacteristic == null) {
              _responseCharacteristic = characteristic;
              
              // Subscribe to notifications
              await characteristic.setNotifyValue(true);
              _responseSubscription = characteristic.lastValueStream.listen((data) {
                String response = utf8.decode(data);
                Logger.command('Received response: $response');
                _commandResponseController.add(response);
              });
              
              Logger.ble('Generic response characteristic found: ${characteristic.uuid}');
            }
          }
        }
      }

      if (_commandCharacteristic != null && _responseCharacteristic != null) {
        _notificationService.showSuccess(
          title: 'Communication Ready',
          message: 'Nordic UART Service configured successfully',
        );
        Logger.ble('Command channel: ${_commandCharacteristic?.uuid}');
        Logger.ble('Response channel: ${_responseCharacteristic?.uuid}');
      } else {
        List<String> missing = [];
        if (_commandCharacteristic == null) missing.add('RX (command)');
        if (_responseCharacteristic == null) missing.add('TX (response)');
        
        _notificationService.showWarning(
          title: 'Partial Setup',
          message: 'Missing characteristics: ${missing.join(", ")}',
        );
      }

    } catch (e) {
      Logger.error('Error setting up Nordic UART characteristics', error: e);
      _notificationService.showError(
        title: 'Communication Setup Failed',
        message: 'Failed to setup Nordic UART communication: $e',
      );
    }
  }

  // Send text command to device
  Future<bool> sendCommand(String command) async {
    if (_commandCharacteristic == null) {
      _notificationService.showError(
        title: 'No Command Channel',
        message: 'Command characteristic not available',
      );
      return false;
    }

    try {
      List<int> commandBytes = utf8.encode(command);
      await _commandCharacteristic!.write(commandBytes, withoutResponse: false);
      
      // Silent operation - command sending feedback shown in UI
      Logger.command('Command sent: $command');
      return true;

    } catch (e) {
      Logger.error('Error sending command', error: e);
      _notificationService.showError(
        title: 'Send Failed',
        message: 'Failed to send command: $e',
      );
      return false;
    }
  }

  // Get available command characteristics info
  Map<String, dynamic> getCommandInfo() {
    return {
      'hasCommandChannel': _commandCharacteristic != null,
      'hasResponseChannel': _responseCharacteristic != null,
      'commandUuid': _commandCharacteristic?.uuid.toString(),
      'responseUuid': _responseCharacteristic?.uuid.toString(),
      'mtu': targetMtu,
    };
  }

  // Clean up command communication resources
  void _cleanupCommandCharacteristics() {
    _responseSubscription?.cancel();
    _responseSubscription = null;
    _commandCharacteristic = null;
    _responseCharacteristic = null;
    Logger.debug('Command characteristics cleaned up');
  }

  void dispose() {
    _adapterStateSubscription?.cancel();
    _scanResultsSubscription?.cancel();
    _responseSubscription?.cancel();
    _devicesController.close();
    _scanningController.close();
    _connectedDeviceController.close();
    _commandResponseController.close();
  }
}