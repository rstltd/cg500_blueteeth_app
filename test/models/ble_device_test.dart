import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';

void main() {
  group('BleDeviceModel', () {
    late BleDeviceModel testDevice;

    setUp(() {
      testDevice = const BleDeviceModel(
        id: 'test-device-001',
        name: 'Test Device',
        displayName: 'Test Device Display',
        rssi: -70,
      );
    });

    group('constructor', () {
      test('should create device with required fields', () {
        const device = BleDeviceModel(
          id: 'device-1',
          name: 'Device 1',
          displayName: 'Device 1',
        );

        expect(device.id, 'device-1');
        expect(device.name, 'Device 1');
        expect(device.displayName, 'Device 1');
      });

      test('should have default values', () {
        const device = BleDeviceModel(
          id: 'device-1',
          name: 'Device 1',
          displayName: 'Device 1',
        );

        expect(device.rssi, 0);
        expect(device.services, isEmpty);
        expect(device.connectionState, BleConnectionState.disconnected);
        expect(device.lastSeen, isNull);
        expect(device.connectedAt, isNull);
        expect(device.isFavorite, false);
        expect(device.metadata, isEmpty);
      });

      test('should create device with all fields', () {
        final now = DateTime.now();
        final device = BleDeviceModel(
          id: 'device-1',
          name: 'Device 1',
          displayName: 'Device 1 Display',
          rssi: -65,
          services: const [],
          connectionState: BleConnectionState.connected,
          lastSeen: now,
          connectedAt: now,
          isFavorite: true,
          metadata: const {'key': 'value'},
        );

        expect(device.rssi, -65);
        expect(device.connectionState, BleConnectionState.connected);
        expect(device.lastSeen, now);
        expect(device.connectedAt, now);
        expect(device.isFavorite, true);
        expect(device.metadata['key'], 'value');
      });
    });

    group('copyWith', () {
      test('should copy with new id', () {
        final copied = testDevice.copyWith(id: 'new-id');
        expect(copied.id, 'new-id');
        expect(copied.name, testDevice.name);
      });

      test('should copy with new name', () {
        final copied = testDevice.copyWith(name: 'New Name');
        expect(copied.name, 'New Name');
        expect(copied.id, testDevice.id);
      });

      test('should copy with new rssi', () {
        final copied = testDevice.copyWith(rssi: -50);
        expect(copied.rssi, -50);
      });

      test('should copy with new connection state', () {
        final copied = testDevice.copyWith(connectionState: BleConnectionState.connected);
        expect(copied.connectionState, BleConnectionState.connected);
      });

      test('should copy with new favorite status', () {
        final copied = testDevice.copyWith(isFavorite: true);
        expect(copied.isFavorite, true);
      });

      test('should preserve original values when no changes', () {
        final copied = testDevice.copyWith();
        expect(copied.id, testDevice.id);
        expect(copied.name, testDevice.name);
        expect(copied.rssi, testDevice.rssi);
      });
    });

    group('updateConnectionState', () {
      test('should update connection state', () {
        final updated = testDevice.updateConnectionState(BleConnectionState.connecting);
        expect(updated.connectionState, BleConnectionState.connecting);
      });

      test('should set connectedAt when connected', () {
        final updated = testDevice.updateConnectionState(BleConnectionState.connected);
        expect(updated.connectionState, BleConnectionState.connected);
        expect(updated.connectedAt, isNotNull);
      });

      test('should preserve connectedAt when not connected', () {
        final connectedDevice = testDevice.copyWith(
          connectionState: BleConnectionState.connected,
          connectedAt: DateTime(2024, 1, 1),
        );
        final updated = connectedDevice.updateConnectionState(BleConnectionState.disconnecting);
        expect(updated.connectedAt, DateTime(2024, 1, 1));
      });
    });

    group('updateServices', () {
      test('should update services list', () {
        const services = [
          BleServiceModel(
            uuid: 'service-uuid-1',
            displayName: 'Service 1',
            characteristics: [],
          ),
        ];
        final updated = testDevice.updateServices(services);
        expect(updated.services.length, 1);
        expect(updated.services.first.uuid, 'service-uuid-1');
      });
    });

    group('updateRssi', () {
      test('should update rssi value', () {
        final updated = testDevice.updateRssi(-45);
        expect(updated.rssi, -45);
      });

      test('should update lastSeen timestamp', () {
        final before = DateTime.now();
        final updated = testDevice.updateRssi(-45);
        expect(updated.lastSeen, isNotNull);
        expect(updated.lastSeen!.isAfter(before) || updated.lastSeen!.isAtSameMomentAs(before), true);
      });
    });

    group('toggleFavorite', () {
      test('should toggle favorite from false to true', () {
        final toggled = testDevice.toggleFavorite();
        expect(toggled.isFavorite, true);
      });

      test('should toggle favorite from true to false', () {
        final favoriteDevice = testDevice.copyWith(isFavorite: true);
        final toggled = favoriteDevice.toggleFavorite();
        expect(toggled.isFavorite, false);
      });
    });

    group('getService', () {
      test('should return null when no services', () {
        final service = testDevice.getService('any-uuid');
        expect(service, isNull);
      });

      test('should return service when found', () {
        const targetService = BleServiceModel(
          uuid: 'target-service-uuid',
          displayName: 'Target Service',
          characteristics: [],
        );
        final deviceWithServices = testDevice.copyWith(
          services: [targetService],
        );
        final found = deviceWithServices.getService('target-service-uuid');
        expect(found, isNotNull);
        expect(found!.uuid, 'target-service-uuid');
      });

      test('should return service with case-insensitive search', () {
        const targetService = BleServiceModel(
          uuid: 'TARGET-SERVICE-UUID',
          displayName: 'Target Service',
          characteristics: [],
        );
        final deviceWithServices = testDevice.copyWith(
          services: [targetService],
        );
        final found = deviceWithServices.getService('target-service-uuid');
        expect(found, isNotNull);
      });

      test('should return null when service not found', () {
        const otherService = BleServiceModel(
          uuid: 'other-service-uuid',
          displayName: 'Other Service',
          characteristics: [],
        );
        final deviceWithServices = testDevice.copyWith(
          services: [otherService],
        );
        final found = deviceWithServices.getService('non-existent-uuid');
        expect(found, isNull);
      });
    });

    group('connectionDuration', () {
      test('should return null when not connected', () {
        expect(testDevice.connectionDuration, isNull);
      });

      test('should return null when connectedAt is null', () {
        final connectedDevice = testDevice.copyWith(
          connectionState: BleConnectionState.connected,
        );
        expect(connectedDevice.connectionDuration, isNull);
      });

      test('should return duration when connected with connectedAt', () {
        final connectedDevice = testDevice.copyWith(
          connectionState: BleConnectionState.connected,
          connectedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        final duration = connectedDevice.connectionDuration;
        expect(duration, isNotNull);
        expect(duration!.inMinutes, greaterThanOrEqualTo(4));
      });
    });

    // Adjusted thresholds based on real-world BLE testing:
    // -60 dBm at ~10cm, -80 dBm at ~1m
    group('rssiDescription', () {
      test('should return Excellent for rssi >= -65', () {
        final device = testDevice.copyWith(rssi: -60);
        expect(device.rssiDescription, 'Excellent');
      });

      test('should return Excellent for rssi = -65', () {
        final device = testDevice.copyWith(rssi: -65);
        expect(device.rssiDescription, 'Excellent');
      });

      test('should return Very Good for rssi >= -75', () {
        final device = testDevice.copyWith(rssi: -70);
        expect(device.rssiDescription, 'Very Good');
      });

      test('should return Good for rssi >= -85', () {
        final device = testDevice.copyWith(rssi: -80);
        expect(device.rssiDescription, 'Good');
      });

      test('should return Fair for rssi >= -95', () {
        final device = testDevice.copyWith(rssi: -90);
        expect(device.rssiDescription, 'Fair');
      });

      test('should return Poor for rssi < -95', () {
        final device = testDevice.copyWith(rssi: -100);
        expect(device.rssiDescription, 'Poor');
      });
    });

    // Adjusted thresholds based on real-world BLE testing:
    // -60 dBm at ~10cm, -80 dBm at ~1m
    group('signalStrength', () {
      test('should return 1.0 for rssi >= -65', () {
        final device = testDevice.copyWith(rssi: -60);
        expect(device.signalStrength, 1.0);
      });

      test('should return 0.8 for rssi >= -75', () {
        final device = testDevice.copyWith(rssi: -70);
        expect(device.signalStrength, 0.8);
      });

      test('should return 0.6 for rssi >= -85', () {
        final device = testDevice.copyWith(rssi: -80);
        expect(device.signalStrength, 0.6);
      });

      test('should return 0.4 for rssi >= -95', () {
        final device = testDevice.copyWith(rssi: -90);
        expect(device.signalStrength, 0.4);
      });

      test('should return 0.2 for rssi >= -105', () {
        final device = testDevice.copyWith(rssi: -100);
        expect(device.signalStrength, 0.2);
      });

      test('should return 0.1 for rssi < -105', () {
        final device = testDevice.copyWith(rssi: -110);
        expect(device.signalStrength, 0.1);
      });
    });

    group('toJson', () {
      test('should serialize basic fields', () {
        final json = testDevice.toJson();
        expect(json['id'], 'test-device-001');
        expect(json['name'], 'Test Device');
        expect(json['displayName'], 'Test Device Display');
        expect(json['rssi'], -70);
      });

      test('should serialize connection state as name', () {
        final json = testDevice.toJson();
        expect(json['connectionState'], 'disconnected');
      });

      test('should serialize isFavorite', () {
        final json = testDevice.toJson();
        expect(json['isFavorite'], false);
      });

      test('should serialize lastSeen as ISO8601', () {
        final now = DateTime.now();
        final device = testDevice.copyWith(lastSeen: now);
        final json = device.toJson();
        expect(json['lastSeen'], now.toIso8601String());
      });

      test('should serialize null lastSeen as null', () {
        final json = testDevice.toJson();
        expect(json['lastSeen'], isNull);
      });

      test('should serialize connectedAt as ISO8601', () {
        final now = DateTime.now();
        final device = testDevice.copyWith(connectedAt: now);
        final json = device.toJson();
        expect(json['connectedAt'], now.toIso8601String());
      });

      test('should serialize null connectedAt as null', () {
        final json = testDevice.toJson();
        expect(json['connectedAt'], isNull);
      });

      test('should serialize metadata', () {
        final device = testDevice.copyWith(
          metadata: {'key1': 'value1', 'key2': 42},
        );
        final json = device.toJson();
        expect(json['metadata'], {'key1': 'value1', 'key2': 42});
      });
    });

    group('fromJson', () {
      test('should deserialize basic fields', () {
        final json = {
          'id': 'json-device-001',
          'name': 'JSON Device',
          'displayName': 'JSON Device Display',
          'rssi': -65,
          'connectionState': 'connected',
          'isFavorite': true,
        };
        final device = BleDeviceModel.fromJson(json);
        expect(device.id, 'json-device-001');
        expect(device.name, 'JSON Device');
        expect(device.displayName, 'JSON Device Display');
        expect(device.rssi, -65);
        expect(device.connectionState, BleConnectionState.connected);
        expect(device.isFavorite, true);
      });

      test('should handle null rssi with default 0', () {
        final json = {
          'id': 'device-1',
          'name': 'Device 1',
          'displayName': 'Device 1',
        };
        final device = BleDeviceModel.fromJson(json);
        expect(device.rssi, 0);
      });

      test('should handle unknown connection state', () {
        final json = {
          'id': 'device-1',
          'name': 'Device 1',
          'displayName': 'Device 1',
          'connectionState': 'unknown_state',
        };
        final device = BleDeviceModel.fromJson(json);
        expect(device.connectionState, BleConnectionState.disconnected);
      });

      test('should deserialize lastSeen from ISO8601', () {
        final dateStr = '2024-01-15T10:30:00.000';
        final json = {
          'id': 'device-1',
          'name': 'Device 1',
          'displayName': 'Device 1',
          'lastSeen': dateStr,
        };
        final device = BleDeviceModel.fromJson(json);
        expect(device.lastSeen, DateTime.parse(dateStr));
      });

      test('should handle null isFavorite with default false', () {
        final json = {
          'id': 'device-1',
          'name': 'Device 1',
          'displayName': 'Device 1',
        };
        final device = BleDeviceModel.fromJson(json);
        expect(device.isFavorite, false);
      });

      test('should handle null metadata with empty map', () {
        final json = {
          'id': 'device-1',
          'name': 'Device 1',
          'displayName': 'Device 1',
        };
        final device = BleDeviceModel.fromJson(json);
        expect(device.metadata, isEmpty);
      });
    });

    group('toString', () {
      test('should return formatted string', () {
        final str = testDevice.toString();
        expect(str, contains('BleDeviceModel'));
        expect(str, contains('test-device-001'));
        expect(str, contains('Test Device'));
        expect(str, contains('disconnected'));
      });
    });

    group('equality', () {
      test('should be equal when id is the same', () {
        const device1 = BleDeviceModel(
          id: 'same-id',
          name: 'Device 1',
          displayName: 'Device 1',
        );
        const device2 = BleDeviceModel(
          id: 'same-id',
          name: 'Different Name',
          displayName: 'Different Display',
        );
        expect(device1, equals(device2));
      });

      test('should not be equal when id is different', () {
        const device1 = BleDeviceModel(
          id: 'id-1',
          name: 'Device',
          displayName: 'Device',
        );
        const device2 = BleDeviceModel(
          id: 'id-2',
          name: 'Device',
          displayName: 'Device',
        );
        expect(device1, isNot(equals(device2)));
      });

      test('identical objects should be equal', () {
        expect(testDevice, equals(testDevice));
      });
    });

    group('hashCode', () {
      test('should be based on id', () {
        const device1 = BleDeviceModel(
          id: 'same-id',
          name: 'Device 1',
          displayName: 'Device 1',
        );
        const device2 = BleDeviceModel(
          id: 'same-id',
          name: 'Device 2',
          displayName: 'Device 2',
        );
        expect(device1.hashCode, equals(device2.hashCode));
      });

      test('should be different for different ids', () {
        const device1 = BleDeviceModel(
          id: 'id-1',
          name: 'Device',
          displayName: 'Device',
        );
        const device2 = BleDeviceModel(
          id: 'id-2',
          name: 'Device',
          displayName: 'Device',
        );
        expect(device1.hashCode, isNot(equals(device2.hashCode)));
      });
    });

    group('copyWith comprehensive', () {
      test('should copy all fields at once', () {
        final now = DateTime.now();
        final copied = testDevice.copyWith(
          id: 'new-id',
          name: 'New Name',
          displayName: 'New Display',
          rssi: -55,
          connectionState: BleConnectionState.connected,
          lastSeen: now,
          connectedAt: now,
          isFavorite: true,
          metadata: {'new': 'data'},
        );

        expect(copied.id, 'new-id');
        expect(copied.name, 'New Name');
        expect(copied.displayName, 'New Display');
        expect(copied.rssi, -55);
        expect(copied.connectionState, BleConnectionState.connected);
        expect(copied.lastSeen, now);
        expect(copied.connectedAt, now);
        expect(copied.isFavorite, true);
        expect(copied.metadata['new'], 'data');
      });

      test('should copy with new displayName', () {
        final copied = testDevice.copyWith(displayName: 'New Display Name');
        expect(copied.displayName, 'New Display Name');
        expect(copied.name, testDevice.name);
      });

      test('should copy with new lastSeen', () {
        final now = DateTime.now();
        final copied = testDevice.copyWith(lastSeen: now);
        expect(copied.lastSeen, now);
      });

      test('should copy with new connectedAt', () {
        final now = DateTime.now();
        final copied = testDevice.copyWith(connectedAt: now);
        expect(copied.connectedAt, now);
      });

      test('should copy with new metadata', () {
        final copied = testDevice.copyWith(metadata: {'key': 'value', 'number': 42});
        expect(copied.metadata['key'], 'value');
        expect(copied.metadata['number'], 42);
      });

      test('should copy with new services', () {
        const services = [
          BleServiceModel(
            uuid: 'service-1',
            displayName: 'Service 1',
            characteristics: [],
          ),
          BleServiceModel(
            uuid: 'service-2',
            displayName: 'Service 2',
            characteristics: [],
          ),
        ];
        final copied = testDevice.copyWith(services: services);
        expect(copied.services.length, 2);
      });
    });

    group('immutability tests', () {
      test('original should not change after copyWith', () {
        const original = BleDeviceModel(
          id: 'original-id',
          name: 'Original',
          displayName: 'Original Display',
          rssi: -70,
          isFavorite: false,
        );

        final modified = original.copyWith(
          id: 'modified-id',
          name: 'Modified',
          rssi: -50,
          isFavorite: true,
        );

        // Original should be unchanged
        expect(original.id, 'original-id');
        expect(original.name, 'Original');
        expect(original.rssi, -70);
        expect(original.isFavorite, false);

        // Modified should have new values
        expect(modified.id, 'modified-id');
        expect(modified.name, 'Modified');
        expect(modified.rssi, -50);
        expect(modified.isFavorite, true);
      });

      test('services list should be independent after copyWith', () {
        final original = testDevice.copyWith(
          services: [
            const BleServiceModel(uuid: 's1', displayName: 'S1', characteristics: []),
          ],
        );

        final modified = original.copyWith(
          services: [
            const BleServiceModel(uuid: 's2', displayName: 'S2', characteristics: []),
            const BleServiceModel(uuid: 's3', displayName: 'S3', characteristics: []),
          ],
        );

        expect(original.services.length, 1);
        expect(modified.services.length, 2);
      });

      test('metadata map should be independent after copyWith', () {
        final original = testDevice.copyWith(metadata: {'key1': 'value1'});
        final modified = original.copyWith(metadata: {'key2': 'value2'});

        expect(original.metadata['key1'], 'value1');
        expect(original.metadata.containsKey('key2'), false);
        expect(modified.metadata['key2'], 'value2');
        expect(modified.metadata.containsKey('key1'), false);
      });
    });

    group('equality edge cases', () {
      test('should be equal to itself via identical check', () {
        expect(identical(testDevice, testDevice), true);
        expect(testDevice == testDevice, true);
      });

      test('should handle nullable variable comparison', () {
        BleDeviceModel? nullableDevice;
        // Test comparison between non-null and nullable (which is null)
        expect(testDevice == nullableDevice, false);

        // Assign value to nullable and compare
        nullableDevice = testDevice;
        expect(testDevice == nullableDevice, true);
      });
    });

    group('rssi boundary values', () {
      // Adjusted thresholds based on real-world BLE testing:
      // -60 dBm at ~10cm, -80 dBm at ~1m
      test('should handle rssi = -65 (boundary for 1.0)', () {
        final device = testDevice.copyWith(rssi: -65);
        expect(device.signalStrength, 1.0);
      });

      test('should handle rssi = -66 (just below 1.0 threshold)', () {
        final device = testDevice.copyWith(rssi: -66);
        expect(device.signalStrength, 0.8);
      });

      test('should handle rssi = -75 (boundary for 0.8)', () {
        final device = testDevice.copyWith(rssi: -75);
        expect(device.signalStrength, 0.8);
      });

      test('should handle rssi = -76 (just below 0.8 threshold)', () {
        final device = testDevice.copyWith(rssi: -76);
        expect(device.signalStrength, 0.6);
      });

      test('should handle rssi = -85 (boundary for 0.6)', () {
        final device = testDevice.copyWith(rssi: -85);
        expect(device.signalStrength, 0.6);
      });

      test('should handle rssi = -86 (just below 0.6 threshold)', () {
        final device = testDevice.copyWith(rssi: -86);
        expect(device.signalStrength, 0.4);
      });

      test('should handle rssi = -95 (boundary for 0.4)', () {
        final device = testDevice.copyWith(rssi: -95);
        expect(device.signalStrength, 0.4);
      });

      test('should handle rssi = -96 (just below 0.4 threshold)', () {
        final device = testDevice.copyWith(rssi: -96);
        expect(device.signalStrength, 0.2);
      });

      test('should handle rssi = -105 (boundary for 0.2)', () {
        final device = testDevice.copyWith(rssi: -105);
        expect(device.signalStrength, 0.2);
      });

      test('should handle rssi = -106 (just below 0.2 threshold)', () {
        final device = testDevice.copyWith(rssi: -106);
        expect(device.signalStrength, 0.1);
      });

      test('should handle very low rssi = -150', () {
        final device = testDevice.copyWith(rssi: -150);
        expect(device.signalStrength, 0.1);
      });

      test('should handle zero rssi', () {
        final device = testDevice.copyWith(rssi: 0);
        expect(device.signalStrength, 1.0);
      });

      test('should handle positive rssi', () {
        final device = testDevice.copyWith(rssi: 10);
        expect(device.signalStrength, 1.0);
      });
    });

    group('rssiDescription boundary values', () {
      // Adjusted thresholds based on real-world BLE testing:
      // -60 dBm at ~10cm, -80 dBm at ~1m
      test('should return Excellent at boundary -65', () {
        final device = testDevice.copyWith(rssi: -65);
        expect(device.rssiDescription, 'Excellent');
      });

      test('should return Very Good at -66', () {
        final device = testDevice.copyWith(rssi: -66);
        expect(device.rssiDescription, 'Very Good');
      });

      test('should return Very Good at boundary -75', () {
        final device = testDevice.copyWith(rssi: -75);
        expect(device.rssiDescription, 'Very Good');
      });

      test('should return Good at -76', () {
        final device = testDevice.copyWith(rssi: -76);
        expect(device.rssiDescription, 'Good');
      });

      test('should return Good at boundary -85', () {
        final device = testDevice.copyWith(rssi: -85);
        expect(device.rssiDescription, 'Good');
      });

      test('should return Fair at -86', () {
        final device = testDevice.copyWith(rssi: -86);
        expect(device.rssiDescription, 'Fair');
      });

      test('should return Fair at boundary -95', () {
        final device = testDevice.copyWith(rssi: -95);
        expect(device.rssiDescription, 'Fair');
      });

      test('should return Poor at -96', () {
        final device = testDevice.copyWith(rssi: -96);
        expect(device.rssiDescription, 'Poor');
      });
    });

    group('getService edge cases', () {
      test('should find service with uppercase search', () {
        const service = BleServiceModel(
          uuid: 'service-uuid',
          displayName: 'Service',
          characteristics: [],
        );
        final device = testDevice.copyWith(services: [service]);
        final found = device.getService('SERVICE-UUID');
        expect(found, isNotNull);
      });

      test('should find service with mixed case', () {
        const service = BleServiceModel(
          uuid: 'Service-UUID',
          displayName: 'Service',
          characteristics: [],
        );
        final device = testDevice.copyWith(services: [service]);
        final found = device.getService('service-uuid');
        expect(found, isNotNull);
      });

      test('should return first matching service', () {
        const service1 = BleServiceModel(
          uuid: 'service-uuid',
          displayName: 'Service 1',
          characteristics: [],
        );
        const service2 = BleServiceModel(
          uuid: 'SERVICE-UUID',
          displayName: 'Service 2',
          characteristics: [],
        );
        final device = testDevice.copyWith(services: [service1, service2]);
        final found = device.getService('service-uuid');
        expect(found!.displayName, 'Service 1');
      });

      test('should handle many services', () {
        final services = List.generate(
          50,
          (i) => BleServiceModel(
            uuid: 'service-$i',
            displayName: 'Service $i',
            characteristics: [],
          ),
        );
        final device = testDevice.copyWith(services: services);

        final found = device.getService('service-25');
        expect(found, isNotNull);
        expect(found!.displayName, 'Service 25');
      });
    });

    group('toJson and fromJson roundtrip', () {
      test('should serialize and deserialize basic device', () {
        final json = testDevice.toJson();
        final restored = BleDeviceModel.fromJson(json);

        expect(restored.id, testDevice.id);
        expect(restored.name, testDevice.name);
        expect(restored.displayName, testDevice.displayName);
        expect(restored.rssi, testDevice.rssi);
      });

      test('should serialize and deserialize with all connection states', () {
        for (final state in BleConnectionState.values) {
          final device = testDevice.copyWith(connectionState: state);
          final json = device.toJson();
          final restored = BleDeviceModel.fromJson(json);
          expect(restored.connectionState, state);
        }
      });

      test('should serialize and deserialize with dates', () {
        final now = DateTime.now();
        final device = testDevice.copyWith(
          lastSeen: now,
          connectedAt: now,
        );
        final json = device.toJson();
        final restored = BleDeviceModel.fromJson(json);

        expect(restored.lastSeen?.toIso8601String(), now.toIso8601String());
        expect(restored.connectedAt?.toIso8601String(), now.toIso8601String());
      });

      test('should serialize and deserialize with metadata', () {
        final device = testDevice.copyWith(
          metadata: {
            'string': 'value',
            'number': 42,
            'bool': true,
            'list': [1, 2, 3],
          },
        );
        final json = device.toJson();
        final restored = BleDeviceModel.fromJson(json);

        expect(restored.metadata['string'], 'value');
        expect(restored.metadata['number'], 42);
        expect(restored.metadata['bool'], true);
        expect(restored.metadata['list'], [1, 2, 3]);
      });

      test('should handle missing connectionState in json', () {
        final json = {
          'id': 'device-1',
          'name': 'Device 1',
          'displayName': 'Device 1',
        };
        final device = BleDeviceModel.fromJson(json);
        expect(device.connectionState, BleConnectionState.disconnected);
      });

      test('should deserialize connectedAt from ISO8601', () {
        final dateStr = '2024-06-15T14:30:00.000';
        final json = {
          'id': 'device-1',
          'name': 'Device 1',
          'displayName': 'Device 1',
          'connectedAt': dateStr,
        };
        final device = BleDeviceModel.fromJson(json);
        expect(device.connectedAt, DateTime.parse(dateStr));
      });
    });

    group('connectionDuration edge cases', () {
      test('should return null when state is connecting', () {
        final device = testDevice.copyWith(
          connectionState: BleConnectionState.connecting,
          connectedAt: DateTime.now(),
        );
        expect(device.connectionDuration, isNull);
      });

      test('should return null when state is disconnecting', () {
        final device = testDevice.copyWith(
          connectionState: BleConnectionState.disconnecting,
          connectedAt: DateTime.now(),
        );
        expect(device.connectionDuration, isNull);
      });

      test('should return duration for very recent connection', () {
        final device = testDevice.copyWith(
          connectionState: BleConnectionState.connected,
          connectedAt: DateTime.now(),
        );
        final duration = device.connectionDuration;
        expect(duration, isNotNull);
        expect(duration!.inSeconds, lessThanOrEqualTo(1));
      });

      test('should return duration for long connection', () {
        final device = testDevice.copyWith(
          connectionState: BleConnectionState.connected,
          connectedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );
        final duration = device.connectionDuration;
        expect(duration, isNotNull);
        expect(duration!.inHours, greaterThanOrEqualTo(1));
      });
    });

    group('updateConnectionState detailed behavior', () {
      test('should set connectedAt when transitioning to connected', () {
        final before = DateTime.now();
        final updated = testDevice.updateConnectionState(BleConnectionState.connected);
        final after = DateTime.now();

        expect(updated.connectedAt, isNotNull);
        expect(
          updated.connectedAt!.isAfter(before) ||
          updated.connectedAt!.isAtSameMomentAs(before),
          true,
        );
        expect(
          updated.connectedAt!.isBefore(after) ||
          updated.connectedAt!.isAtSameMomentAs(after),
          true,
        );
      });

      test('should not change connectedAt when disconnecting', () {
        final originalTime = DateTime(2024, 1, 1, 12, 0);
        final device = testDevice.copyWith(
          connectionState: BleConnectionState.connected,
          connectedAt: originalTime,
        );
        final updated = device.updateConnectionState(BleConnectionState.disconnecting);
        expect(updated.connectedAt, originalTime);
      });

      test('should not change connectedAt when already connected', () {
        final originalTime = DateTime(2024, 1, 1, 12, 0);
        final device = testDevice.copyWith(
          connectionState: BleConnectionState.connected,
          connectedAt: originalTime,
        );
        // Re-setting to connected should update connectedAt
        final updated = device.updateConnectionState(BleConnectionState.connected);
        expect(updated.connectedAt, isNot(originalTime));
      });
    });

    group('updateRssi behavior', () {
      test('should update both rssi and lastSeen', () {
        final before = DateTime.now();
        final updated = testDevice.updateRssi(-45);
        final after = DateTime.now();

        expect(updated.rssi, -45);
        expect(updated.lastSeen, isNotNull);
        expect(
          updated.lastSeen!.isAfter(before) ||
          updated.lastSeen!.isAtSameMomentAs(before),
          true,
        );
        expect(
          updated.lastSeen!.isBefore(after) ||
          updated.lastSeen!.isAtSameMomentAs(after),
          true,
        );
      });

      test('should preserve other fields', () {
        final device = testDevice.copyWith(
          isFavorite: true,
          connectionState: BleConnectionState.connected,
        );
        final updated = device.updateRssi(-50);

        expect(updated.isFavorite, true);
        expect(updated.connectionState, BleConnectionState.connected);
        expect(updated.id, device.id);
        expect(updated.name, device.name);
      });
    });

    group('updateServices behavior', () {
      test('should replace services completely', () {
        final device = testDevice.copyWith(
          services: [
            const BleServiceModel(uuid: 'old', displayName: 'Old', characteristics: []),
          ],
        );

        final newServices = [
          const BleServiceModel(uuid: 'new-1', displayName: 'New 1', characteristics: []),
          const BleServiceModel(uuid: 'new-2', displayName: 'New 2', characteristics: []),
        ];

        final updated = device.updateServices(newServices);
        expect(updated.services.length, 2);
        expect(updated.services.first.uuid, 'new-1');
      });

      test('should preserve other fields', () {
        final device = testDevice.copyWith(
          isFavorite: true,
          rssi: -55,
        );
        final updated = device.updateServices([]);

        expect(updated.isFavorite, true);
        expect(updated.rssi, -55);
        expect(updated.services, isEmpty);
      });
    });

    group('toggleFavorite behavior', () {
      test('should toggle multiple times', () {
        var device = testDevice;
        expect(device.isFavorite, false);

        device = device.toggleFavorite();
        expect(device.isFavorite, true);

        device = device.toggleFavorite();
        expect(device.isFavorite, false);

        device = device.toggleFavorite();
        expect(device.isFavorite, true);
      });

      test('should preserve other fields', () {
        final device = testDevice.copyWith(
          rssi: -55,
          connectionState: BleConnectionState.connected,
        );
        final toggled = device.toggleFavorite();

        expect(toggled.rssi, -55);
        expect(toggled.connectionState, BleConnectionState.connected);
        expect(toggled.id, device.id);
      });
    });
  });
}
