import 'dart:async';
import '../../models/ble_device.dart';
import '../../models/ble_service.dart';

/// Interface for Bluetooth Low Energy (BLE) services.
///
/// Implementations of this interface provide BLE device scanning,
/// connection management, service discovery, and command communication.
abstract class BleServiceInterface {
  // ============================================
  // Streams for reactive UI updates
  // ============================================

  /// Stream of discovered BLE devices.
  Stream<List<BleDeviceModel>> get devicesStream;

  /// Stream indicating whether scanning is in progress.
  Stream<bool> get scanningStream;

  /// Stream of the currently connected device (null when disconnected).
  Stream<BleDeviceModel?> get connectedDeviceStream;

  /// Stream of command responses from the connected device.
  Stream<String> get commandResponseStream;

  // ============================================
  // State getters
  // ============================================

  /// List of all scanned devices.
  List<BleDeviceModel> get scannedDevices;

  /// Currently connected device, or null if not connected.
  BleDeviceModel? get connectedDevice;

  /// Whether the service is currently scanning for devices.
  bool get isScanning;

  /// Whether the service has been initialized.
  bool get isInitialized;

  // ============================================
  // Lifecycle operations
  // ============================================

  /// Initialize the BLE service.
  ///
  /// This should be called before any other operations. It checks for
  /// Bluetooth support, requests permissions, and sets up listeners.
  ///
  /// Returns `true` if initialization was successful.
  Future<bool> initialize();

  /// Release all resources held by this service.
  void dispose();

  // ============================================
  // Bluetooth state operations
  // ============================================

  /// Check if Bluetooth is currently enabled on the device.
  Future<bool> isBluetoothEnabled();

  /// Attempt to turn on Bluetooth.
  ///
  /// This may not work on all platforms or may require user interaction.
  Future<void> turnOnBluetooth();

  // ============================================
  // Scanning operations
  // ============================================

  /// Start scanning for BLE devices.
  ///
  /// [timeout] specifies how long to scan before automatically stopping.
  /// Defaults to 15 seconds if not specified.
  ///
  /// Returns `true` if scanning started successfully.
  Future<bool> startScanning({Duration timeout = const Duration(seconds: 15)});

  /// Stop scanning for devices.
  Future<void> stopScanning();

  /// Clear the list of scanned devices.
  void clearScannedDevices();

  // ============================================
  // Connection operations
  // ============================================

  /// Connect to a BLE device by its ID.
  ///
  /// Returns `true` if the connection was successful.
  Future<bool> connectToDevice(String deviceId);

  /// Disconnect from the currently connected device.
  Future<void> disconnectDevice();

  // ============================================
  // Service discovery and communication
  // ============================================

  /// Discover GATT services on a connected device.
  ///
  /// Returns a list of discovered services with their characteristics.
  Future<List<BleServiceModel>> discoverServices(String deviceId);

  /// Send a text command to the connected device.
  ///
  /// Uses the Nordic UART Service if available.
  /// Returns `true` if the command was sent successfully.
  Future<bool> sendCommand(String command);

  /// Get information about the command communication channels.
  ///
  /// Returns a map with keys like 'hasCommandChannel', 'hasResponseChannel',
  /// 'commandUuid', 'responseUuid', and 'mtu'.
  Map<String, dynamic> getCommandInfo();
}
