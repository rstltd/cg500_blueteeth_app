import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleCharacteristicModel {
  final String uuid;
  final String displayName;
  final List<BleCharacteristicProperty> properties;
  final List<int>? lastValue;
  final DateTime? lastUpdated;
  final bool isNotifying;

  const BleCharacteristicModel({
    required this.uuid,
    required this.displayName,
    required this.properties,
    this.lastValue,
    this.lastUpdated,
    this.isNotifying = false,
  });

  factory BleCharacteristicModel.fromBluetoothCharacteristic(
    BluetoothCharacteristic characteristic,
  ) {
    return BleCharacteristicModel(
      uuid: characteristic.uuid.toString(),
      displayName: _getCharacteristicName(characteristic.uuid.toString()),
      properties: _mapProperties(characteristic.properties),
    );
  }

  BleCharacteristicModel copyWith({
    String? uuid,
    String? displayName,
    List<BleCharacteristicProperty>? properties,
    List<int>? lastValue,
    DateTime? lastUpdated,
    bool? isNotifying,
  }) {
    return BleCharacteristicModel(
      uuid: uuid ?? this.uuid,
      displayName: displayName ?? this.displayName,
      properties: properties ?? this.properties,
      lastValue: lastValue ?? this.lastValue,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isNotifying: isNotifying ?? this.isNotifying,
    );
  }

  String get lastValueAsHex {
    if (lastValue == null || lastValue!.isEmpty) return 'No data';
    return lastValue!
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(' ');
  }

  String get lastValueAsString {
    if (lastValue == null || lastValue!.isEmpty) return 'No data';
    try {
      return String.fromCharCodes(lastValue!);
    } catch (e) {
      return 'Binary data';
    }
  }

  bool get canRead => properties.contains(BleCharacteristicProperty.read);
  bool get canWrite => 
      properties.contains(BleCharacteristicProperty.write) ||
      properties.contains(BleCharacteristicProperty.writeWithoutResponse);
  bool get canNotify =>
      properties.contains(BleCharacteristicProperty.notify) ||
      properties.contains(BleCharacteristicProperty.indicate);

  static String _getCharacteristicName(String uuid) {
    final Map<String, String> knownCharacteristics = {
      '00002a00-0000-1000-8000-00805f9b34fb': 'Device Name',
      '00002a01-0000-1000-8000-00805f9b34fb': 'Appearance',
      '00002a04-0000-1000-8000-00805f9b34fb': 'Peripheral Preferred Connection Parameters',
      '00002a19-0000-1000-8000-00805f9b34fb': 'Battery Level',
      '00002a6e-0000-1000-8000-00805f9b34fb': 'Temperature',
      '00002a6f-0000-1000-8000-00805f9b34fb': 'Humidity',
    };

    return knownCharacteristics[uuid.toLowerCase()] ?? 
           'Characteristic ${_safeSubstring(uuid, 4, 8).toUpperCase()}';
  }

  static String _safeSubstring(String str, int start, int end) {
    if (start >= str.length) return '';
    if (end > str.length) end = str.length;
    if (start >= end) return '';
    return str.substring(start, end);
  }

  static List<BleCharacteristicProperty> _mapProperties(
    CharacteristicProperties properties,
  ) {
    final List<BleCharacteristicProperty> result = [];
    
    if (properties.read) result.add(BleCharacteristicProperty.read);
    if (properties.write) result.add(BleCharacteristicProperty.write);
    if (properties.writeWithoutResponse) {
      result.add(BleCharacteristicProperty.writeWithoutResponse);
    }
    if (properties.notify) result.add(BleCharacteristicProperty.notify);
    if (properties.indicate) result.add(BleCharacteristicProperty.indicate);
    
    return result;
  }

  @override
  String toString() {
    return 'BleCharacteristicModel(uuid: $uuid, displayName: $displayName, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BleCharacteristicModel && other.uuid == uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}

enum BleCharacteristicProperty {
  read,
  write,
  writeWithoutResponse,
  notify,
  indicate,
}

extension BleCharacteristicPropertyExtension on BleCharacteristicProperty {
  String get displayName {
    switch (this) {
      case BleCharacteristicProperty.read:
        return 'Read';
      case BleCharacteristicProperty.write:
        return 'Write';
      case BleCharacteristicProperty.writeWithoutResponse:
        return 'Write No Response';
      case BleCharacteristicProperty.notify:
        return 'Notify';
      case BleCharacteristicProperty.indicate:
        return 'Indicate';
    }
  }
}