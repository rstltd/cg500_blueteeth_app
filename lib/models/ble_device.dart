import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../l10n/app_strings.dart';
import 'ble_service.dart';
import 'connection_state.dart';

class BleDeviceModel {
  final String id;
  final String name;
  final String displayName;
  final int rssi;
  final List<BleServiceModel> services;
  final BleConnectionState connectionState;
  final DateTime? lastSeen;
  final DateTime? connectedAt;
  final bool isFavorite;
  final Map<String, dynamic> metadata;

  const BleDeviceModel({
    required this.id,
    required this.name,
    required this.displayName,
    this.rssi = 0,
    this.services = const [],
    this.connectionState = BleConnectionState.disconnected,
    this.lastSeen,
    this.connectedAt,
    this.isFavorite = false,
    this.metadata = const {},
  });

  factory BleDeviceModel.fromBluetoothDevice(
    BluetoothDevice device, {
    int rssi = 0,
    List<BluetoothService>? services,
  }) {
    return BleDeviceModel(
      id: device.remoteId.toString(),
      name: device.platformName,
      displayName: device.platformName.isNotEmpty 
          ? device.platformName 
          : AppStrings.unknownDevice,
      rssi: rssi,
      services: services?.map((s) => BleServiceModel.fromBluetoothService(s)).toList() ?? [],
      lastSeen: DateTime.now(),
    );
  }

  BleDeviceModel copyWith({
    String? id,
    String? name,
    String? displayName,
    int? rssi,
    List<BleServiceModel>? services,
    BleConnectionState? connectionState,
    DateTime? lastSeen,
    DateTime? connectedAt,
    bool? isFavorite,
    Map<String, dynamic>? metadata,
  }) {
    return BleDeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      rssi: rssi ?? this.rssi,
      services: services ?? this.services,
      connectionState: connectionState ?? this.connectionState,
      lastSeen: lastSeen ?? this.lastSeen,
      connectedAt: connectedAt ?? this.connectedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      metadata: metadata ?? this.metadata,
    );
  }

  BleDeviceModel updateConnectionState(BleConnectionState newState) {
    return copyWith(
      connectionState: newState,
      connectedAt: newState == BleConnectionState.connected ? DateTime.now() : connectedAt,
    );
  }

  BleDeviceModel updateServices(List<BleServiceModel> newServices) {
    return copyWith(services: newServices);
  }

  BleDeviceModel updateRssi(int newRssi) {
    return copyWith(
      rssi: newRssi,
      lastSeen: DateTime.now(),
    );
  }

  BleDeviceModel toggleFavorite() {
    return copyWith(isFavorite: !isFavorite);
  }

  BleServiceModel? getService(String serviceUuid) {
    try {
      return services.firstWhere(
        (service) => service.uuid.toLowerCase() == serviceUuid.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  Duration? get connectionDuration {
    if (connectedAt == null || !connectionState.isConnected) {
      return null;
    }
    return DateTime.now().difference(connectedAt!);
  }

  // Adjusted thresholds based on real-world BLE testing:
  // -60 dBm at ~10cm, -80 dBm at ~1m
  String get rssiDescription {
    if (rssi >= -65) return AppStrings.signalQualityExcellent;
    if (rssi >= -75) return AppStrings.signalQualityVeryGood;
    if (rssi >= -85) return AppStrings.signalQualityGood;
    if (rssi >= -95) return AppStrings.signalQualityFair;
    return AppStrings.signalQualityPoor;
  }

  double get signalStrength {
    // Convert RSSI to a 0-1 scale for UI display
    // Adjusted for real-world BLE signal ranges:
    // -60 dBm at ~10cm, -80 dBm at ~1m
    if (rssi >= -65) return 1.0;
    if (rssi >= -75) return 0.8;
    if (rssi >= -85) return 0.6;
    if (rssi >= -95) return 0.4;
    if (rssi >= -105) return 0.2;
    return 0.1;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'rssi': rssi,
      'connectionState': connectionState.name,
      'lastSeen': lastSeen?.toIso8601String(),
      'connectedAt': connectedAt?.toIso8601String(),
      'isFavorite': isFavorite,
      'metadata': metadata,
    };
  }

  factory BleDeviceModel.fromJson(Map<String, dynamic> json) {
    return BleDeviceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      rssi: json['rssi'] as int? ?? 0,
      connectionState: BleConnectionState.values.firstWhere(
        (e) => e.name == json['connectionState'],
        orElse: () => BleConnectionState.disconnected,
      ),
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      connectedAt: json['connectedAt'] != null 
          ? DateTime.parse(json['connectedAt'] as String)
          : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  @override
  String toString() {
    return 'BleDeviceModel(id: $id, name: $name, connectionState: $connectionState)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BleDeviceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}