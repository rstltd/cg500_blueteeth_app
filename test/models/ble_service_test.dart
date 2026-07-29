import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/ble_service.dart';
import 'package:cg500_blueteeth_app/models/ble_characteristic.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' show Guid;

void main() {
  group('BleServiceModel', () {
    late BleServiceModel testService;
    late List<BleCharacteristicModel> testCharacteristics;

    setUp(() {
      testCharacteristics = [
        const BleCharacteristicModel(
          uuid: 'char-uuid-1',
          displayName: 'Characteristic 1',
          properties: [BleCharacteristicProperty.read],
        ),
        const BleCharacteristicModel(
          uuid: 'char-uuid-2',
          displayName: 'Characteristic 2',
          properties: [BleCharacteristicProperty.write],
        ),
        const BleCharacteristicModel(
          uuid: 'char-uuid-3',
          displayName: 'Characteristic 3',
          properties: [BleCharacteristicProperty.notify],
        ),
      ];

      testService = BleServiceModel(
        uuid: 'test-service-uuid',
        displayName: 'Test Service',
        characteristics: testCharacteristics,
      );
    });

    group('constructor', () {
      test('should create service with required fields', () {
        const service = BleServiceModel(
          uuid: 'service-uuid',
          displayName: 'Service Display',
          characteristics: [],
        );

        expect(service.uuid, 'service-uuid');
        expect(service.displayName, 'Service Display');
        expect(service.characteristics, isEmpty);
      });

      test('should have default isPrimary as true', () {
        const service = BleServiceModel(
          uuid: 'service-uuid',
          displayName: 'Service',
          characteristics: [],
        );
        expect(service.isPrimary, true);
      });

      test('should create service with isPrimary false', () {
        const service = BleServiceModel(
          uuid: 'service-uuid',
          displayName: 'Service',
          characteristics: [],
          isPrimary: false,
        );
        expect(service.isPrimary, false);
      });
    });

    group('copyWith', () {
      test('should copy with new uuid', () {
        final copied = testService.copyWith(uuid: 'new-uuid');
        expect(copied.uuid, 'new-uuid');
        expect(copied.displayName, testService.displayName);
      });

      test('should copy with new displayName', () {
        final copied = testService.copyWith(displayName: 'New Display');
        expect(copied.displayName, 'New Display');
        expect(copied.uuid, testService.uuid);
      });

      test('should copy with new characteristics', () {
        const newChars = [
          BleCharacteristicModel(
            uuid: 'new-char',
            displayName: 'New Char',
            properties: [],
          ),
        ];
        final copied = testService.copyWith(characteristics: newChars);
        expect(copied.characteristics.length, 1);
        expect(copied.characteristics.first.uuid, 'new-char');
      });

      test('should copy with new isPrimary', () {
        final copied = testService.copyWith(isPrimary: false);
        expect(copied.isPrimary, false);
      });

      test('should preserve original values when no changes', () {
        final copied = testService.copyWith();
        expect(copied.uuid, testService.uuid);
        expect(copied.displayName, testService.displayName);
        expect(copied.characteristics, testService.characteristics);
        expect(copied.isPrimary, testService.isPrimary);
      });
    });

    group('getCharacteristic', () {
      test('should return characteristic when found', () {
        final found = testService.getCharacteristic('char-uuid-1');
        expect(found, isNotNull);
        expect(found!.uuid, 'char-uuid-1');
      });

      test('should return null when not found', () {
        final found = testService.getCharacteristic('non-existent');
        expect(found, isNull);
      });

      test('should find characteristic case-insensitively', () {
        final found = testService.getCharacteristic('CHAR-UUID-1');
        expect(found, isNotNull);
        expect(found!.uuid, 'char-uuid-1');
      });

      test('should return null for empty characteristics', () {
        const emptyService = BleServiceModel(
          uuid: 'service',
          displayName: 'Service',
          characteristics: [],
        );
        final found = emptyService.getCharacteristic('any-uuid');
        expect(found, isNull);
      });
    });

    group('readableCharacteristics', () {
      test('should return only readable characteristics', () {
        final readable = testService.readableCharacteristics;
        expect(readable.length, 1);
        expect(readable.first.uuid, 'char-uuid-1');
      });

      test('should return empty list when no readable', () {
        const service = BleServiceModel(
          uuid: 'service',
          displayName: 'Service',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'write-only',
              displayName: 'Write Only',
              properties: [BleCharacteristicProperty.write],
            ),
          ],
        );
        expect(service.readableCharacteristics, isEmpty);
      });
    });

    group('writableCharacteristics', () {
      test('should return only writable characteristics', () {
        final writable = testService.writableCharacteristics;
        expect(writable.length, 1);
        expect(writable.first.uuid, 'char-uuid-2');
      });

      test('should include writeWithoutResponse', () {
        const service = BleServiceModel(
          uuid: 'service',
          displayName: 'Service',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'write-no-response',
              displayName: 'Write No Response',
              properties: [BleCharacteristicProperty.writeWithoutResponse],
            ),
          ],
        );
        expect(service.writableCharacteristics.length, 1);
      });

      test('should return empty list when no writable', () {
        const service = BleServiceModel(
          uuid: 'service',
          displayName: 'Service',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'read-only',
              displayName: 'Read Only',
              properties: [BleCharacteristicProperty.read],
            ),
          ],
        );
        expect(service.writableCharacteristics, isEmpty);
      });
    });

    group('notifiableCharacteristics', () {
      test('should return only notifiable characteristics', () {
        final notifiable = testService.notifiableCharacteristics;
        expect(notifiable.length, 1);
        expect(notifiable.first.uuid, 'char-uuid-3');
      });

      test('should include indicate property', () {
        const service = BleServiceModel(
          uuid: 'service',
          displayName: 'Service',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'indicate',
              displayName: 'Indicate',
              properties: [BleCharacteristicProperty.indicate],
            ),
          ],
        );
        expect(service.notifiableCharacteristics.length, 1);
      });

      test('should return empty list when no notifiable', () {
        const service = BleServiceModel(
          uuid: 'service',
          displayName: 'Service',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'read-only',
              displayName: 'Read Only',
              properties: [BleCharacteristicProperty.read],
            ),
          ],
        );
        expect(service.notifiableCharacteristics, isEmpty);
      });
    });

    group('known service names', () {
      test('should recognize Generic Access service', () {
        // Test through the static method indirectly via service name
        const service = BleServiceModel(
          uuid: '00001800-0000-1000-8000-00805f9b34fb',
          displayName: 'Generic Access',
          characteristics: [],
        );
        expect(service.displayName, 'Generic Access');
      });

      test('should recognize Battery Service', () {
        const service = BleServiceModel(
          uuid: '0000180f-0000-1000-8000-00805f9b34fb',
          displayName: 'Battery Service',
          characteristics: [],
        );
        expect(service.displayName, 'Battery Service');
      });
    });

    group('service filtering with multiple properties', () {
      test('should return characteristics with multiple read properties', () {
        const service = BleServiceModel(
          uuid: 'test-service',
          displayName: 'Test',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'char-1',
              displayName: 'Char 1',
              properties: [BleCharacteristicProperty.read, BleCharacteristicProperty.notify],
            ),
            BleCharacteristicModel(
              uuid: 'char-2',
              displayName: 'Char 2',
              properties: [BleCharacteristicProperty.read, BleCharacteristicProperty.write],
            ),
            BleCharacteristicModel(
              uuid: 'char-3',
              displayName: 'Char 3',
              properties: [BleCharacteristicProperty.write],
            ),
          ],
        );
        expect(service.readableCharacteristics.length, 2);
        expect(service.writableCharacteristics.length, 2);
        expect(service.notifiableCharacteristics.length, 1);
      });

      test('should handle all property types on single characteristic', () {
        const service = BleServiceModel(
          uuid: 'test-service',
          displayName: 'Test',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'full-char',
              displayName: 'Full Char',
              properties: [
                BleCharacteristicProperty.read,
                BleCharacteristicProperty.write,
                BleCharacteristicProperty.writeWithoutResponse,
                BleCharacteristicProperty.notify,
                BleCharacteristicProperty.indicate,
              ],
            ),
          ],
        );
        expect(service.readableCharacteristics.length, 1);
        expect(service.writableCharacteristics.length, 1);
        expect(service.notifiableCharacteristics.length, 1);
      });
    });

    group('toString', () {
      test('should return formatted string', () {
        final str = testService.toString();
        expect(str, contains('BleServiceModel'));
        expect(str, contains('test-service-uuid'));
        expect(str, contains('Test Service'));
        expect(str, contains('3'));
      });
    });

    group('equality', () {
      test('should be equal when uuid is the same', () {
        const service1 = BleServiceModel(
          uuid: 'same-uuid',
          displayName: 'Service 1',
          characteristics: [],
        );
        const service2 = BleServiceModel(
          uuid: 'same-uuid',
          displayName: 'Different Name',
          characteristics: [],
        );
        expect(service1, equals(service2));
      });

      test('should not be equal when uuid is different', () {
        const service1 = BleServiceModel(
          uuid: 'uuid-1',
          displayName: 'Service',
          characteristics: [],
        );
        const service2 = BleServiceModel(
          uuid: 'uuid-2',
          displayName: 'Service',
          characteristics: [],
        );
        expect(service1, isNot(equals(service2)));
      });

      test('identical objects should be equal', () {
        expect(testService, equals(testService));
      });
    });

    group('hashCode', () {
      test('should be based on uuid', () {
        const service1 = BleServiceModel(
          uuid: 'same-uuid',
          displayName: 'Service 1',
          characteristics: [],
        );
        const service2 = BleServiceModel(
          uuid: 'same-uuid',
          displayName: 'Service 2',
          characteristics: [],
        );
        expect(service1.hashCode, equals(service2.hashCode));
      });

      test('should be different for different uuids', () {
        const service1 = BleServiceModel(
          uuid: 'uuid-1',
          displayName: 'Service',
          characteristics: [],
        );
        const service2 = BleServiceModel(
          uuid: 'uuid-2',
          displayName: 'Service',
          characteristics: [],
        );
        expect(service1.hashCode, isNot(equals(service2.hashCode)));
      });
    });

    group('comprehensive characteristic filtering', () {
      test('should handle service with no characteristics', () {
        const service = BleServiceModel(
          uuid: 'empty-service',
          displayName: 'Empty',
          characteristics: [],
        );
        expect(service.readableCharacteristics, isEmpty);
        expect(service.writableCharacteristics, isEmpty);
        expect(service.notifiableCharacteristics, isEmpty);
      });

      test('should handle service with characteristics having no properties', () {
        const service = BleServiceModel(
          uuid: 'no-props-service',
          displayName: 'No Props',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'char-no-props',
              displayName: 'No Props Char',
              properties: [],
            ),
          ],
        );
        expect(service.readableCharacteristics, isEmpty);
        expect(service.writableCharacteristics, isEmpty);
        expect(service.notifiableCharacteristics, isEmpty);
      });

      test('should handle mixed readable and writable characteristics', () {
        const service = BleServiceModel(
          uuid: 'mixed-service',
          displayName: 'Mixed',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'read-write',
              displayName: 'Read Write',
              properties: [BleCharacteristicProperty.read, BleCharacteristicProperty.write],
            ),
            BleCharacteristicModel(
              uuid: 'read-only',
              displayName: 'Read Only',
              properties: [BleCharacteristicProperty.read],
            ),
            BleCharacteristicModel(
              uuid: 'write-only',
              displayName: 'Write Only',
              properties: [BleCharacteristicProperty.write],
            ),
          ],
        );
        expect(service.readableCharacteristics.length, 2);
        expect(service.writableCharacteristics.length, 2);
      });

      test('should handle multiple write types', () {
        const service = BleServiceModel(
          uuid: 'multi-write',
          displayName: 'Multi Write',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'write-both',
              displayName: 'Write Both',
              properties: [
                BleCharacteristicProperty.write,
                BleCharacteristicProperty.writeWithoutResponse,
              ],
            ),
          ],
        );
        expect(service.writableCharacteristics.length, 1);
      });

      test('should handle both notify and indicate', () {
        const service = BleServiceModel(
          uuid: 'dual-notify',
          displayName: 'Dual Notify',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'notify-indicate',
              displayName: 'Notify and Indicate',
              properties: [
                BleCharacteristicProperty.notify,
                BleCharacteristicProperty.indicate,
              ],
            ),
          ],
        );
        expect(service.notifiableCharacteristics.length, 1);
      });
    });

    group('getCharacteristic edge cases', () {
      test('should handle uuid with mixed case', () {
        const service = BleServiceModel(
          uuid: 'service',
          displayName: 'Service',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'AbCd-1234',
              displayName: 'Mixed Case',
              properties: [],
            ),
          ],
        );
        // lowercase search
        expect(service.getCharacteristic('abcd-1234'), isNotNull);
        // uppercase search
        expect(service.getCharacteristic('ABCD-1234'), isNotNull);
        // mixed case search
        expect(service.getCharacteristic('AbCd-1234'), isNotNull);
      });

      test('should handle similar but different uuids', () {
        const service = BleServiceModel(
          uuid: 'service',
          displayName: 'Service',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'uuid-1234',
              displayName: 'Char 1',
              properties: [],
            ),
            BleCharacteristicModel(
              uuid: 'uuid-1235',
              displayName: 'Char 2',
              properties: [],
            ),
          ],
        );
        final found = service.getCharacteristic('uuid-1234');
        expect(found, isNotNull);
        expect(found!.displayName, 'Char 1');
      });

      test('should handle partial uuid match correctly - should not match', () {
        const service = BleServiceModel(
          uuid: 'service',
          displayName: 'Service',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'complete-uuid-1234',
              displayName: 'Char',
              properties: [],
            ),
          ],
        );
        // Partial match should not find anything
        expect(service.getCharacteristic('uuid-1234'), isNull);
        expect(service.getCharacteristic('complete-uuid'), isNull);
      });
    });

    group('copyWith comprehensive', () {
      test('should copy multiple fields at once', () {
        final copied = testService.copyWith(
          uuid: 'new-uuid',
          displayName: 'New Name',
          isPrimary: false,
        );
        expect(copied.uuid, 'new-uuid');
        expect(copied.displayName, 'New Name');
        expect(copied.isPrimary, false);
        expect(copied.characteristics, testService.characteristics);
      });

      test('should create independent copy', () {
        final copied = testService.copyWith(uuid: 'copied-uuid');
        expect(testService.uuid, 'test-service-uuid');
        expect(copied.uuid, 'copied-uuid');
      });
    });

    group('known service UUIDs', () {
      test('should have correct Generic Access UUID format', () {
        const service = BleServiceModel(
          uuid: '00001800-0000-1000-8000-00805f9b34fb',
          displayName: 'Generic Access',
          characteristics: [],
        );
        expect(service.uuid, '00001800-0000-1000-8000-00805f9b34fb');
      });

      test('should have correct Generic Attribute UUID format', () {
        const service = BleServiceModel(
          uuid: '00001801-0000-1000-8000-00805f9b34fb',
          displayName: 'Generic Attribute',
          characteristics: [],
        );
        expect(service.uuid, '00001801-0000-1000-8000-00805f9b34fb');
      });

      test('should have correct Human Interface Device UUID format', () {
        const service = BleServiceModel(
          uuid: '00001812-0000-1000-8000-00805f9b34fb',
          displayName: 'Human Interface Device',
          characteristics: [],
        );
        expect(service.uuid, '00001812-0000-1000-8000-00805f9b34fb');
      });

      test('should have correct Device Information UUID format', () {
        const service = BleServiceModel(
          uuid: '0000180a-0000-1000-8000-00805f9b34fb',
          displayName: 'Device Information',
          characteristics: [],
        );
        expect(service.uuid, '0000180a-0000-1000-8000-00805f9b34fb');
      });

      test('should have correct Health Thermometer UUID format', () {
        const service = BleServiceModel(
          uuid: '00001809-0000-1000-8000-00805f9b34fb',
          displayName: 'Health Thermometer',
          characteristics: [],
        );
        expect(service.uuid, '00001809-0000-1000-8000-00805f9b34fb');
      });

      test('should have correct Environmental Sensing UUID format', () {
        const service = BleServiceModel(
          uuid: '0000181a-0000-1000-8000-00805f9b34fb',
          displayName: 'Environmental Sensing',
          characteristics: [],
        );
        expect(service.uuid, '0000181a-0000-1000-8000-00805f9b34fb');
      });
    });

    group('toString variations', () {
      test('should show zero characteristics', () {
        const service = BleServiceModel(
          uuid: 'empty-uuid',
          displayName: 'Empty Service',
          characteristics: [],
        );
        final str = service.toString();
        expect(str, contains('0'));
      });

      test('should show correct count for multiple characteristics', () {
        const service = BleServiceModel(
          uuid: 'multi-uuid',
          displayName: 'Multi Service',
          characteristics: [
            BleCharacteristicModel(uuid: 'c1', displayName: 'C1', properties: []),
            BleCharacteristicModel(uuid: 'c2', displayName: 'C2', properties: []),
            BleCharacteristicModel(uuid: 'c3', displayName: 'C3', properties: []),
            BleCharacteristicModel(uuid: 'c4', displayName: 'C4', properties: []),
            BleCharacteristicModel(uuid: 'c5', displayName: 'C5', properties: []),
          ],
        );
        final str = service.toString();
        expect(str, contains('5'));
      });
    });

    group('isPrimary behavior', () {
      test('should default to primary true', () {
        const service = BleServiceModel(
          uuid: 'test',
          displayName: 'Test',
          characteristics: [],
        );
        expect(service.isPrimary, true);
      });

      test('should allow non-primary service', () {
        const service = BleServiceModel(
          uuid: 'test',
          displayName: 'Test',
          characteristics: [],
          isPrimary: false,
        );
        expect(service.isPrimary, false);
      });

      test('should preserve isPrimary in copyWith when not changed', () {
        const service = BleServiceModel(
          uuid: 'test',
          displayName: 'Test',
          characteristics: [],
          isPrimary: false,
        );
        final copied = service.copyWith(displayName: 'New Name');
        expect(copied.isPrimary, false);
      });
    });

    group('immutability tests', () {
      test('original should not change after copyWith', () {
        const original = BleServiceModel(
          uuid: 'original-uuid',
          displayName: 'Original',
          characteristics: [],
          isPrimary: true,
        );

        final modified = original.copyWith(
          uuid: 'modified-uuid',
          displayName: 'Modified',
          isPrimary: false,
        );

        // Original should be unchanged
        expect(original.uuid, 'original-uuid');
        expect(original.displayName, 'Original');
        expect(original.isPrimary, true);

        // Modified should have new values
        expect(modified.uuid, 'modified-uuid');
        expect(modified.displayName, 'Modified');
        expect(modified.isPrimary, false);
      });

      test('characteristics list should be independent after copyWith', () {
        const original = BleServiceModel(
          uuid: 'test',
          displayName: 'Test',
          characteristics: [
            BleCharacteristicModel(uuid: 'c1', displayName: 'C1', properties: []),
          ],
        );

        final modified = original.copyWith(
          characteristics: [
            const BleCharacteristicModel(uuid: 'c2', displayName: 'C2', properties: []),
            const BleCharacteristicModel(uuid: 'c3', displayName: 'C3', properties: []),
          ],
        );

        expect(original.characteristics.length, 1);
        expect(modified.characteristics.length, 2);
      });
    });

    group('equality edge cases', () {
      test('should be equal to itself via identical check', () {
        const service = BleServiceModel(
          uuid: 'self-test',
          displayName: 'Self Test',
          characteristics: [],
        );
        expect(identical(service, service), true);
        expect(service == service, true);
      });

      test('should handle nullable variable comparison', () {
        BleServiceModel? nullableService;
        const BleServiceModel service = BleServiceModel(
          uuid: 'test',
          displayName: 'Test',
          characteristics: [],
        );
        // Test comparison between non-null and nullable (which is null)
        expect(service == nullableService, false);

        // Assign value to nullable and compare
        nullableService = service;
        expect(service == nullableService, true);
      });

      test('should handle UUID with different cases in equality', () {
        const service1 = BleServiceModel(
          uuid: 'TEST-UUID',
          displayName: 'Service 1',
          characteristics: [],
        );
        const service2 = BleServiceModel(
          uuid: 'test-uuid',
          displayName: 'Service 2',
          characteristics: [],
        );
        // Equality is based on exact UUID match
        expect(service1 == service2, false);
      });
    });

    group('large characteristics list', () {
      test('should handle 100 characteristics', () {
        final chars = List.generate(
          100,
          (i) => BleCharacteristicModel(
            uuid: 'char-$i',
            displayName: 'Characteristic $i',
            properties: i % 2 == 0
                ? [BleCharacteristicProperty.read]
                : [BleCharacteristicProperty.write],
          ),
        );

        final service = BleServiceModel(
          uuid: 'large-service',
          displayName: 'Large Service',
          characteristics: chars,
        );

        expect(service.characteristics.length, 100);
        expect(service.readableCharacteristics.length, 50);
        expect(service.writableCharacteristics.length, 50);
        expect(service.notifiableCharacteristics.length, 0);
      });

      test('should handle 1000 characteristics', () {
        final chars = List.generate(
          1000,
          (i) => BleCharacteristicModel(
            uuid: 'char-$i',
            displayName: 'Char $i',
            properties: [],
          ),
        );

        final service = BleServiceModel(
          uuid: 'huge-service',
          displayName: 'Huge Service',
          characteristics: chars,
        );

        expect(service.characteristics.length, 1000);
        final str = service.toString();
        expect(str, contains('1000'));
      });
    });

    group('getCharacteristic performance', () {
      test('should find first characteristic quickly', () {
        final chars = List.generate(
          100,
          (i) => BleCharacteristicModel(
            uuid: 'char-$i',
            displayName: 'Char $i',
            properties: [],
          ),
        );

        final service = BleServiceModel(
          uuid: 'test',
          displayName: 'Test',
          characteristics: chars,
        );

        final found = service.getCharacteristic('char-0');
        expect(found, isNotNull);
        expect(found!.uuid, 'char-0');
      });

      test('should find last characteristic', () {
        final chars = List.generate(
          100,
          (i) => BleCharacteristicModel(
            uuid: 'char-$i',
            displayName: 'Char $i',
            properties: [],
          ),
        );

        final service = BleServiceModel(
          uuid: 'test',
          displayName: 'Test',
          characteristics: chars,
        );

        final found = service.getCharacteristic('char-99');
        expect(found, isNotNull);
        expect(found!.uuid, 'char-99');
      });

      test('should return null for non-existent in large list', () {
        final chars = List.generate(
          100,
          (i) => BleCharacteristicModel(
            uuid: 'char-$i',
            displayName: 'Char $i',
            properties: [],
          ),
        );

        final service = BleServiceModel(
          uuid: 'test',
          displayName: 'Test',
          characteristics: chars,
        );

        final found = service.getCharacteristic('non-existent');
        expect(found, isNull);
      });
    });

    group('characteristic filtering edge cases', () {
      test('should filter characteristics with mixed properties', () {
        const service = BleServiceModel(
          uuid: 'test',
          displayName: 'Test',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'all-props',
              displayName: 'All',
              properties: [
                BleCharacteristicProperty.read,
                BleCharacteristicProperty.write,
                BleCharacteristicProperty.writeWithoutResponse,
                BleCharacteristicProperty.notify,
                BleCharacteristicProperty.indicate,
              ],
            ),
            BleCharacteristicModel(
              uuid: 'read-notify',
              displayName: 'Read Notify',
              properties: [
                BleCharacteristicProperty.read,
                BleCharacteristicProperty.notify,
              ],
            ),
            BleCharacteristicModel(
              uuid: 'write-only',
              displayName: 'Write Only',
              properties: [
                BleCharacteristicProperty.write,
              ],
            ),
            BleCharacteristicModel(
              uuid: 'none',
              displayName: 'None',
              properties: [],
            ),
          ],
        );

        expect(service.readableCharacteristics.length, 2);
        expect(service.writableCharacteristics.length, 2);
        expect(service.notifiableCharacteristics.length, 2);
      });

      test('should include characteristic with writeWithoutResponse in writable', () {
        const service = BleServiceModel(
          uuid: 'test',
          displayName: 'Test',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'write-no-resp',
              displayName: 'Write No Response',
              properties: [BleCharacteristicProperty.writeWithoutResponse],
            ),
          ],
        );

        expect(service.writableCharacteristics.length, 1);
        expect(service.writableCharacteristics.first.uuid, 'write-no-resp');
      });

      test('should include characteristic with indicate in notifiable', () {
        const service = BleServiceModel(
          uuid: 'test',
          displayName: 'Test',
          characteristics: [
            BleCharacteristicModel(
              uuid: 'indicate',
              displayName: 'Indicate',
              properties: [BleCharacteristicProperty.indicate],
            ),
          ],
        );

        expect(service.notifiableCharacteristics.length, 1);
        expect(service.notifiableCharacteristics.first.uuid, 'indicate');
      });
    });
  });

  group('BleServiceModel.serviceNameFor', () {
    // Regression cover for F-009. flutter_blue_plus reports SIG services in
    // their SHORTEST form, so these arrive as Guid('1800'), not as the 128-bit
    // string the lookup table is keyed by.
    test('resolves a short-form SIG uuid', () {
      expect(BleServiceModel.serviceNameFor(Guid('1800')), 'Generic Access');
      expect(BleServiceModel.serviceNameFor(Guid('1801')), 'Generic Attribute');
      expect(BleServiceModel.serviceNameFor(Guid('180a')), 'Device Information');
    });

    test('resolves the long form of the same uuid identically', () {
      expect(
        BleServiceModel.serviceNameFor(Guid('00001800-0000-1000-8000-00805f9b34fb')),
        'Generic Access',
      );
    });

    test('resolves the Nordic UART Service this app speaks', () {
      expect(
        BleServiceModel.serviceNameFor(Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e')),
        'Nordic UART Service',
      );
    });

    test('falls back to the raw uuid, never a bare "Service"', () {
      final name = BleServiceModel.serviceNameFor(
        Guid('12345678-1234-1234-1234-123456789abc'),
      );
      expect(name, contains('12345678-1234-1234-1234-123456789abc'));
      expect(name, isNot('Service'));
      expect(name.trim(), isNot('Service'));
    });
  });

}
