import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_characteristic.dart';

class BleServiceModel {
  final String uuid;
  final String displayName;
  final List<BleCharacteristicModel> characteristics;
  final bool isPrimary;

  const BleServiceModel({
    required this.uuid,
    required this.displayName,
    required this.characteristics,
    this.isPrimary = true,
  });

  factory BleServiceModel.fromBluetoothService(BluetoothService service) {
    return BleServiceModel(
      uuid: service.uuid.toString(),
      displayName: _getServiceName(service.uuid.toString()),
      characteristics: service.characteristics
          .map((char) => BleCharacteristicModel.fromBluetoothCharacteristic(char))
          .toList(),
      isPrimary: service.isPrimary,
    );
  }

  BleServiceModel copyWith({
    String? uuid,
    String? displayName,
    List<BleCharacteristicModel>? characteristics,
    bool? isPrimary,
  }) {
    return BleServiceModel(
      uuid: uuid ?? this.uuid,
      displayName: displayName ?? this.displayName,
      characteristics: characteristics ?? this.characteristics,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }

  BleCharacteristicModel? getCharacteristic(String characteristicUuid) {
    try {
      return characteristics.firstWhere(
        (char) => char.uuid.toLowerCase() == characteristicUuid.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  List<BleCharacteristicModel> get readableCharacteristics =>
      characteristics.where((char) => char.canRead).toList();

  List<BleCharacteristicModel> get writableCharacteristics =>
      characteristics.where((char) => char.canWrite).toList();

  List<BleCharacteristicModel> get notifiableCharacteristics =>
      characteristics.where((char) => char.canNotify).toList();

  static String _getServiceName(String uuid) {
    final Map<String, String> knownServices = {
      '00001800-0000-1000-8000-00805f9b34fb': 'Generic Access',
      '00001801-0000-1000-8000-00805f9b34fb': 'Generic Attribute',
      '0000180f-0000-1000-8000-00805f9b34fb': 'Battery Service',
      '00001812-0000-1000-8000-00805f9b34fb': 'Human Interface Device',
      '0000180a-0000-1000-8000-00805f9b34fb': 'Device Information',
      '00001809-0000-1000-8000-00805f9b34fb': 'Health Thermometer',
      '0000181a-0000-1000-8000-00805f9b34fb': 'Environmental Sensing',
    };

    return knownServices[uuid.toLowerCase()] ?? 
           'Service ${_safeSubstring(uuid, 4, 8).toUpperCase()}';
  }

  static String _safeSubstring(String str, int start, int end) {
    if (start >= str.length) return '';
    if (end > str.length) end = str.length;
    if (start >= end) return '';
    return str.substring(start, end);
  }

  @override
  String toString() {
    return 'BleServiceModel(uuid: $uuid, displayName: $displayName, characteristics: ${characteristics.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BleServiceModel && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}