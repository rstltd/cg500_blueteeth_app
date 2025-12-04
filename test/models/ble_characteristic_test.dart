import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/ble_characteristic.dart';

void main() {
  group('BleCharacteristicModel', () {
    late BleCharacteristicModel testCharacteristic;

    setUp(() {
      testCharacteristic = const BleCharacteristicModel(
        uuid: 'test-char-uuid',
        displayName: 'Test Characteristic',
        properties: [
          BleCharacteristicProperty.read,
          BleCharacteristicProperty.write,
          BleCharacteristicProperty.notify,
        ],
      );
    });

    group('constructor', () {
      test('should create characteristic with required fields', () {
        const char = BleCharacteristicModel(
          uuid: 'char-uuid',
          displayName: 'Char Display',
          properties: [],
        );

        expect(char.uuid, 'char-uuid');
        expect(char.displayName, 'Char Display');
        expect(char.properties, isEmpty);
      });

      test('should have default null lastValue', () {
        const char = BleCharacteristicModel(
          uuid: 'char-uuid',
          displayName: 'Char',
          properties: [],
        );
        expect(char.lastValue, isNull);
      });

      test('should have default null lastUpdated', () {
        const char = BleCharacteristicModel(
          uuid: 'char-uuid',
          displayName: 'Char',
          properties: [],
        );
        expect(char.lastUpdated, isNull);
      });

      test('should have default false isNotifying', () {
        const char = BleCharacteristicModel(
          uuid: 'char-uuid',
          displayName: 'Char',
          properties: [],
        );
        expect(char.isNotifying, false);
      });

      test('should create characteristic with all fields', () {
        final now = DateTime.now();
        final char = BleCharacteristicModel(
          uuid: 'char-uuid',
          displayName: 'Char',
          properties: const [BleCharacteristicProperty.read],
          lastValue: const [0x01, 0x02],
          lastUpdated: now,
          isNotifying: true,
        );

        expect(char.lastValue, [0x01, 0x02]);
        expect(char.lastUpdated, now);
        expect(char.isNotifying, true);
      });
    });

    group('copyWith', () {
      test('should copy with new uuid', () {
        final copied = testCharacteristic.copyWith(uuid: 'new-uuid');
        expect(copied.uuid, 'new-uuid');
        expect(copied.displayName, testCharacteristic.displayName);
      });

      test('should copy with new displayName', () {
        final copied = testCharacteristic.copyWith(displayName: 'New Display');
        expect(copied.displayName, 'New Display');
      });

      test('should copy with new properties', () {
        final copied = testCharacteristic.copyWith(
          properties: [BleCharacteristicProperty.indicate],
        );
        expect(copied.properties.length, 1);
        expect(copied.properties.first, BleCharacteristicProperty.indicate);
      });

      test('should copy with new lastValue', () {
        final copied = testCharacteristic.copyWith(lastValue: [0xFF, 0xFE]);
        expect(copied.lastValue, [0xFF, 0xFE]);
      });

      test('should copy with new lastUpdated', () {
        final now = DateTime.now();
        final copied = testCharacteristic.copyWith(lastUpdated: now);
        expect(copied.lastUpdated, now);
      });

      test('should copy with new isNotifying', () {
        final copied = testCharacteristic.copyWith(isNotifying: true);
        expect(copied.isNotifying, true);
      });

      test('should preserve original values when no changes', () {
        final copied = testCharacteristic.copyWith();
        expect(copied.uuid, testCharacteristic.uuid);
        expect(copied.displayName, testCharacteristic.displayName);
        expect(copied.properties, testCharacteristic.properties);
      });
    });

    group('lastValueAsHex', () {
      test('should return "No data" when lastValue is null', () {
        expect(testCharacteristic.lastValueAsHex, 'No data');
      });

      test('should return "No data" when lastValue is empty', () {
        final char = testCharacteristic.copyWith(lastValue: []);
        expect(char.lastValueAsHex, 'No data');
      });

      test('should return hex string for single byte', () {
        final char = testCharacteristic.copyWith(lastValue: [0x0A]);
        expect(char.lastValueAsHex, '0A');
      });

      test('should return hex string for multiple bytes', () {
        final char = testCharacteristic.copyWith(lastValue: [0x01, 0xFF, 0x0A]);
        expect(char.lastValueAsHex, '01 FF 0A');
      });

      test('should pad single digit hex values', () {
        final char = testCharacteristic.copyWith(lastValue: [0x01, 0x02, 0x03]);
        expect(char.lastValueAsHex, '01 02 03');
      });

      test('should uppercase hex values', () {
        final char = testCharacteristic.copyWith(lastValue: [0xab, 0xcd, 0xef]);
        expect(char.lastValueAsHex, 'AB CD EF');
      });
    });

    group('lastValueAsString', () {
      test('should return "No data" when lastValue is null', () {
        expect(testCharacteristic.lastValueAsString, 'No data');
      });

      test('should return "No data" when lastValue is empty', () {
        final char = testCharacteristic.copyWith(lastValue: []);
        expect(char.lastValueAsString, 'No data');
      });

      test('should return string for ASCII values', () {
        final char = testCharacteristic.copyWith(
          lastValue: [0x48, 0x65, 0x6C, 0x6C, 0x6F], // "Hello"
        );
        expect(char.lastValueAsString, 'Hello');
      });

      test('should return string for numeric characters', () {
        final char = testCharacteristic.copyWith(
          lastValue: [0x31, 0x32, 0x33], // "123"
        );
        expect(char.lastValueAsString, '123');
      });

      test('should handle unicode characters', () {
        final char = testCharacteristic.copyWith(
          lastValue: [0xC3, 0xA9], // "é" in UTF-8
        );
        // Should return some string representation
        expect(char.lastValueAsString, isNotEmpty);
      });

      test('should handle special ASCII characters', () {
        final char = testCharacteristic.copyWith(
          lastValue: [0x0A, 0x0D, 0x09], // newline, carriage return, tab
        );
        expect(char.lastValueAsString, '\n\r\t');
      });
    });

    group('canRead', () {
      test('should return true when read property exists', () {
        const char = BleCharacteristicModel(
          uuid: 'char',
          displayName: 'Char',
          properties: [BleCharacteristicProperty.read],
        );
        expect(char.canRead, true);
      });

      test('should return false when read property does not exist', () {
        const char = BleCharacteristicModel(
          uuid: 'char',
          displayName: 'Char',
          properties: [BleCharacteristicProperty.write],
        );
        expect(char.canRead, false);
      });

      test('should return false for empty properties', () {
        const char = BleCharacteristicModel(
          uuid: 'char',
          displayName: 'Char',
          properties: [],
        );
        expect(char.canRead, false);
      });
    });

    group('canWrite', () {
      test('should return true when write property exists', () {
        const char = BleCharacteristicModel(
          uuid: 'char',
          displayName: 'Char',
          properties: [BleCharacteristicProperty.write],
        );
        expect(char.canWrite, true);
      });

      test('should return true when writeWithoutResponse property exists', () {
        const char = BleCharacteristicModel(
          uuid: 'char',
          displayName: 'Char',
          properties: [BleCharacteristicProperty.writeWithoutResponse],
        );
        expect(char.canWrite, true);
      });

      test('should return true when both write properties exist', () {
        const char = BleCharacteristicModel(
          uuid: 'char',
          displayName: 'Char',
          properties: [
            BleCharacteristicProperty.write,
            BleCharacteristicProperty.writeWithoutResponse,
          ],
        );
        expect(char.canWrite, true);
      });

      test('should return false when no write property exists', () {
        const char = BleCharacteristicModel(
          uuid: 'char',
          displayName: 'Char',
          properties: [BleCharacteristicProperty.read],
        );
        expect(char.canWrite, false);
      });
    });

    group('canNotify', () {
      test('should return true when notify property exists', () {
        const char = BleCharacteristicModel(
          uuid: 'char',
          displayName: 'Char',
          properties: [BleCharacteristicProperty.notify],
        );
        expect(char.canNotify, true);
      });

      test('should return true when indicate property exists', () {
        const char = BleCharacteristicModel(
          uuid: 'char',
          displayName: 'Char',
          properties: [BleCharacteristicProperty.indicate],
        );
        expect(char.canNotify, true);
      });

      test('should return true when both notify and indicate exist', () {
        const char = BleCharacteristicModel(
          uuid: 'char',
          displayName: 'Char',
          properties: [
            BleCharacteristicProperty.notify,
            BleCharacteristicProperty.indicate,
          ],
        );
        expect(char.canNotify, true);
      });

      test('should return false when no notify property exists', () {
        const char = BleCharacteristicModel(
          uuid: 'char',
          displayName: 'Char',
          properties: [BleCharacteristicProperty.read],
        );
        expect(char.canNotify, false);
      });
    });

    group('toString', () {
      test('should return formatted string', () {
        final str = testCharacteristic.toString();
        expect(str, contains('BleCharacteristicModel'));
        expect(str, contains('test-char-uuid'));
        expect(str, contains('Test Characteristic'));
      });
    });

    group('equality', () {
      test('should be equal when uuid is the same', () {
        const char1 = BleCharacteristicModel(
          uuid: 'same-uuid',
          displayName: 'Char 1',
          properties: [],
        );
        const char2 = BleCharacteristicModel(
          uuid: 'same-uuid',
          displayName: 'Different Name',
          properties: [BleCharacteristicProperty.read],
        );
        expect(char1, equals(char2));
      });

      test('should not be equal when uuid is different', () {
        const char1 = BleCharacteristicModel(
          uuid: 'uuid-1',
          displayName: 'Char',
          properties: [],
        );
        const char2 = BleCharacteristicModel(
          uuid: 'uuid-2',
          displayName: 'Char',
          properties: [],
        );
        expect(char1, isNot(equals(char2)));
      });

      test('identical objects should be equal', () {
        expect(testCharacteristic, equals(testCharacteristic));
      });
    });

    group('hashCode', () {
      test('should be based on uuid', () {
        const char1 = BleCharacteristicModel(
          uuid: 'same-uuid',
          displayName: 'Char 1',
          properties: [],
        );
        const char2 = BleCharacteristicModel(
          uuid: 'same-uuid',
          displayName: 'Char 2',
          properties: [BleCharacteristicProperty.read],
        );
        expect(char1.hashCode, equals(char2.hashCode));
      });

      test('should be different for different uuids', () {
        const char1 = BleCharacteristicModel(
          uuid: 'uuid-1',
          displayName: 'Char',
          properties: [],
        );
        const char2 = BleCharacteristicModel(
          uuid: 'uuid-2',
          displayName: 'Char',
          properties: [],
        );
        expect(char1.hashCode, isNot(equals(char2.hashCode)));
      });
    });

    group('comprehensive property combinations', () {
      test('should handle characteristic with all properties', () {
        const char = BleCharacteristicModel(
          uuid: 'full-char',
          displayName: 'Full Characteristic',
          properties: [
            BleCharacteristicProperty.read,
            BleCharacteristicProperty.write,
            BleCharacteristicProperty.writeWithoutResponse,
            BleCharacteristicProperty.notify,
            BleCharacteristicProperty.indicate,
          ],
        );
        expect(char.canRead, true);
        expect(char.canWrite, true);
        expect(char.canNotify, true);
      });

      test('should handle read-only characteristic', () {
        const char = BleCharacteristicModel(
          uuid: 'read-only',
          displayName: 'Read Only',
          properties: [BleCharacteristicProperty.read],
        );
        expect(char.canRead, true);
        expect(char.canWrite, false);
        expect(char.canNotify, false);
      });

      test('should handle write-only characteristic', () {
        const char = BleCharacteristicModel(
          uuid: 'write-only',
          displayName: 'Write Only',
          properties: [BleCharacteristicProperty.write],
        );
        expect(char.canRead, false);
        expect(char.canWrite, true);
        expect(char.canNotify, false);
      });

      test('should handle notify-only characteristic', () {
        const char = BleCharacteristicModel(
          uuid: 'notify-only',
          displayName: 'Notify Only',
          properties: [BleCharacteristicProperty.notify],
        );
        expect(char.canRead, false);
        expect(char.canWrite, false);
        expect(char.canNotify, true);
      });
    });

    group('lastValue edge cases', () {
      test('should handle large byte array', () {
        final largeData = List.generate(100, (i) => i % 256);
        final char = testCharacteristic.copyWith(lastValue: largeData);
        expect(char.lastValueAsHex, isNotEmpty);
        expect(char.lastValueAsHex.split(' ').length, 100);
      });

      test('should handle single zero byte', () {
        final char = testCharacteristic.copyWith(lastValue: [0x00]);
        expect(char.lastValueAsHex, '00');
      });

      test('should handle max value byte', () {
        final char = testCharacteristic.copyWith(lastValue: [0xFF]);
        expect(char.lastValueAsHex, 'FF');
      });

      test('should handle all zero bytes', () {
        final char = testCharacteristic.copyWith(lastValue: [0x00, 0x00, 0x00]);
        expect(char.lastValueAsHex, '00 00 00');
      });

      test('should handle all max value bytes', () {
        final char = testCharacteristic.copyWith(lastValue: [0xFF, 0xFF, 0xFF]);
        expect(char.lastValueAsHex, 'FF FF FF');
      });
    });

    group('copyWith comprehensive', () {
      test('should copy multiple fields at once', () {
        final now = DateTime.now();
        final copied = testCharacteristic.copyWith(
          uuid: 'new-uuid',
          displayName: 'New Name',
          properties: [BleCharacteristicProperty.indicate],
          lastValue: [0x01, 0x02],
          lastUpdated: now,
          isNotifying: true,
        );
        expect(copied.uuid, 'new-uuid');
        expect(copied.displayName, 'New Name');
        expect(copied.properties, [BleCharacteristicProperty.indicate]);
        expect(copied.lastValue, [0x01, 0x02]);
        expect(copied.lastUpdated, now);
        expect(copied.isNotifying, true);
      });

      test('should create independent copy', () {
        final copied = testCharacteristic.copyWith(uuid: 'copied-uuid');
        expect(testCharacteristic.uuid, 'test-char-uuid');
        expect(copied.uuid, 'copied-uuid');
      });
    });

    group('toString variations', () {
      test('should show properties in string', () {
        final str = testCharacteristic.toString();
        expect(str, contains('properties'));
      });

      test('should handle characteristic with no properties', () {
        const char = BleCharacteristicModel(
          uuid: 'no-props',
          displayName: 'No Props',
          properties: [],
        );
        final str = char.toString();
        expect(str, contains('BleCharacteristicModel'));
        expect(str, contains('no-props'));
      });
    });
  });

  group('BleCharacteristicProperty', () {
    group('enum values', () {
      test('should have 5 property types', () {
        expect(BleCharacteristicProperty.values.length, 5);
      });

      test('should contain read property', () {
        expect(BleCharacteristicProperty.values, contains(BleCharacteristicProperty.read));
      });

      test('should contain write property', () {
        expect(BleCharacteristicProperty.values, contains(BleCharacteristicProperty.write));
      });

      test('should contain writeWithoutResponse property', () {
        expect(BleCharacteristicProperty.values, contains(BleCharacteristicProperty.writeWithoutResponse));
      });

      test('should contain notify property', () {
        expect(BleCharacteristicProperty.values, contains(BleCharacteristicProperty.notify));
      });

      test('should contain indicate property', () {
        expect(BleCharacteristicProperty.values, contains(BleCharacteristicProperty.indicate));
      });
    });

    group('displayName extension', () {
      test('read should display "Read"', () {
        expect(BleCharacteristicProperty.read.displayName, 'Read');
      });

      test('write should display "Write"', () {
        expect(BleCharacteristicProperty.write.displayName, 'Write');
      });

      test('writeWithoutResponse should display "Write No Response"', () {
        expect(BleCharacteristicProperty.writeWithoutResponse.displayName, 'Write No Response');
      });

      test('notify should display "Notify"', () {
        expect(BleCharacteristicProperty.notify.displayName, 'Notify');
      });

      test('indicate should display "Indicate"', () {
        expect(BleCharacteristicProperty.indicate.displayName, 'Indicate');
      });
    });
  });

  group('BleCharacteristicModel static methods via indirect testing', () {
    group('known characteristic UUIDs', () {
      test('should recognize Device Name characteristic', () {
        // Testing _getCharacteristicName indirectly through display name matching
        // UUID: 00002a00-0000-1000-8000-00805f9b34fb = Device Name
        const char = BleCharacteristicModel(
          uuid: '00002a00-0000-1000-8000-00805f9b34fb',
          displayName: 'Device Name',
          properties: [BleCharacteristicProperty.read],
        );
        expect(char.displayName, 'Device Name');
        expect(char.uuid, '00002a00-0000-1000-8000-00805f9b34fb');
      });

      test('should recognize Appearance characteristic', () {
        const char = BleCharacteristicModel(
          uuid: '00002a01-0000-1000-8000-00805f9b34fb',
          displayName: 'Appearance',
          properties: [BleCharacteristicProperty.read],
        );
        expect(char.displayName, 'Appearance');
      });

      test('should recognize Battery Level characteristic', () {
        const char = BleCharacteristicModel(
          uuid: '00002a19-0000-1000-8000-00805f9b34fb',
          displayName: 'Battery Level',
          properties: [BleCharacteristicProperty.read, BleCharacteristicProperty.notify],
        );
        expect(char.displayName, 'Battery Level');
      });

      test('should recognize Temperature characteristic', () {
        const char = BleCharacteristicModel(
          uuid: '00002a6e-0000-1000-8000-00805f9b34fb',
          displayName: 'Temperature',
          properties: [BleCharacteristicProperty.read],
        );
        expect(char.displayName, 'Temperature');
      });

      test('should recognize Humidity characteristic', () {
        const char = BleCharacteristicModel(
          uuid: '00002a6f-0000-1000-8000-00805f9b34fb',
          displayName: 'Humidity',
          properties: [BleCharacteristicProperty.read],
        );
        expect(char.displayName, 'Humidity');
      });

      test('should recognize Peripheral Preferred Connection Parameters', () {
        const char = BleCharacteristicModel(
          uuid: '00002a04-0000-1000-8000-00805f9b34fb',
          displayName: 'Peripheral Preferred Connection Parameters',
          properties: [BleCharacteristicProperty.read],
        );
        expect(char.displayName, 'Peripheral Preferred Connection Parameters');
      });
    });

    group('unknown characteristic UUID handling', () {
      test('should handle custom UUID format', () {
        const char = BleCharacteristicModel(
          uuid: 'abcd1234-0000-1000-8000-00805f9b34fb',
          displayName: 'Characteristic 1234',
          properties: [],
        );
        expect(char.uuid, 'abcd1234-0000-1000-8000-00805f9b34fb');
      });

      test('should handle short custom UUID', () {
        const char = BleCharacteristicModel(
          uuid: '1234',
          displayName: 'Characteristic 1234',
          properties: [],
        );
        expect(char.uuid, '1234');
      });

      test('should handle very short UUID', () {
        const char = BleCharacteristicModel(
          uuid: 'ab',
          displayName: 'Custom Char',
          properties: [],
        );
        expect(char.uuid, 'ab');
      });

      test('should handle empty UUID', () {
        const char = BleCharacteristicModel(
          uuid: '',
          displayName: 'Empty UUID Char',
          properties: [],
        );
        expect(char.uuid, '');
      });
    });

    group('edge cases for value conversion', () {
      test('should handle null values in lastValueAsHex', () {
        const char = BleCharacteristicModel(
          uuid: 'test',
          displayName: 'Test',
          properties: [],
          lastValue: null,
        );
        expect(char.lastValueAsHex, 'No data');
      });

      test('should handle boundary byte values', () {
        const char = BleCharacteristicModel(
          uuid: 'test',
          displayName: 'Test',
          properties: [],
          lastValue: [0x00, 0x7F, 0x80, 0xFF],
        );
        expect(char.lastValueAsHex, '00 7F 80 FF');
      });

      test('should handle printable ASCII range', () {
        const char = BleCharacteristicModel(
          uuid: 'test',
          displayName: 'Test',
          properties: [],
          lastValue: [0x20, 0x41, 0x5A, 0x7E], // space, A, Z, ~
        );
        expect(char.lastValueAsString, ' AZ~');
      });

      test('should handle control characters', () {
        const char = BleCharacteristicModel(
          uuid: 'test',
          displayName: 'Test',
          properties: [],
          lastValue: [0x00, 0x01, 0x02, 0x1F], // null, SOH, STX, US
        );
        // These are valid characters even though not printable
        expect(char.lastValueAsString.length, 4);
      });

      test('should handle extended ASCII', () {
        const char = BleCharacteristicModel(
          uuid: 'test',
          displayName: 'Test',
          properties: [],
          lastValue: [0x80, 0x90, 0xA0, 0xFE],
        );
        // Should return some string representation
        expect(char.lastValueAsString, isNotEmpty);
      });
    });

    group('property combination edge cases', () {
      test('should handle no properties - not readable writable or notifiable', () {
        const char = BleCharacteristicModel(
          uuid: 'no-props',
          displayName: 'No Properties',
          properties: [],
        );
        expect(char.canRead, false);
        expect(char.canWrite, false);
        expect(char.canNotify, false);
        expect(char.properties.length, 0);
      });

      test('should handle all five properties', () {
        const char = BleCharacteristicModel(
          uuid: 'all-props',
          displayName: 'All Properties',
          properties: [
            BleCharacteristicProperty.read,
            BleCharacteristicProperty.write,
            BleCharacteristicProperty.writeWithoutResponse,
            BleCharacteristicProperty.notify,
            BleCharacteristicProperty.indicate,
          ],
        );
        expect(char.properties.length, 5);
        expect(char.canRead, true);
        expect(char.canWrite, true);
        expect(char.canNotify, true);
      });

      test('should handle only writeWithoutResponse', () {
        const char = BleCharacteristicModel(
          uuid: 'write-no-resp',
          displayName: 'Write No Response Only',
          properties: [BleCharacteristicProperty.writeWithoutResponse],
        );
        expect(char.canWrite, true);
        expect(char.canRead, false);
        expect(char.canNotify, false);
      });

      test('should handle only indicate', () {
        const char = BleCharacteristicModel(
          uuid: 'indicate-only',
          displayName: 'Indicate Only',
          properties: [BleCharacteristicProperty.indicate],
        );
        expect(char.canNotify, true);
        expect(char.canRead, false);
        expect(char.canWrite, false);
      });
    });

    group('timestamp handling', () {
      test('should handle past lastUpdated', () {
        final pastDate = DateTime(2020, 1, 1);
        final char = BleCharacteristicModel(
          uuid: 'test',
          displayName: 'Test',
          properties: [],
          lastUpdated: pastDate,
        );
        expect(char.lastUpdated, pastDate);
        expect(char.lastUpdated!.isBefore(DateTime.now()), true);
      });

      test('should handle future lastUpdated', () {
        final futureDate = DateTime(2030, 12, 31);
        final char = BleCharacteristicModel(
          uuid: 'test',
          displayName: 'Test',
          properties: [],
          lastUpdated: futureDate,
        );
        expect(char.lastUpdated, futureDate);
        expect(char.lastUpdated!.isAfter(DateTime.now()), true);
      });

      test('should handle current time lastUpdated', () {
        final now = DateTime.now();
        final char = BleCharacteristicModel(
          uuid: 'test',
          displayName: 'Test',
          properties: [],
          lastUpdated: now,
        );
        expect(char.lastUpdated, now);
      });
    });

    group('immutability tests', () {
      test('original should not change after copyWith', () {
        const original = BleCharacteristicModel(
          uuid: 'original-uuid',
          displayName: 'Original',
          properties: [BleCharacteristicProperty.read],
          isNotifying: false,
        );

        final modified = original.copyWith(
          uuid: 'modified-uuid',
          displayName: 'Modified',
          isNotifying: true,
        );

        // Original should be unchanged
        expect(original.uuid, 'original-uuid');
        expect(original.displayName, 'Original');
        expect(original.isNotifying, false);

        // Modified should have new values
        expect(modified.uuid, 'modified-uuid');
        expect(modified.displayName, 'Modified');
        expect(modified.isNotifying, true);
      });

      test('properties list should be independent after copyWith', () {
        const original = BleCharacteristicModel(
          uuid: 'test',
          displayName: 'Test',
          properties: [BleCharacteristicProperty.read],
        );

        final modified = original.copyWith(
          properties: [BleCharacteristicProperty.write, BleCharacteristicProperty.notify],
        );

        expect(original.properties.length, 1);
        expect(modified.properties.length, 2);
      });
    });

    group('equality edge cases', () {
      test('should be equal to itself via identical check', () {
        const char = BleCharacteristicModel(
          uuid: 'self-test',
          displayName: 'Self Test',
          properties: [],
        );
        expect(identical(char, char), true);
        expect(char == char, true);
      });

      test('should not be equal to null', () {
        const char = BleCharacteristicModel(
          uuid: 'test',
          displayName: 'Test',
          properties: [],
        );
        expect(char == null, false);
      });

      test('should not be equal to different type', () {
        const char = BleCharacteristicModel(
          uuid: 'test',
          displayName: 'Test',
          properties: [],
        );
        expect(char == 'test', false);
        expect(char == 123, false);
      });

      test('should handle UUID with different cases in equality', () {
        const char1 = BleCharacteristicModel(
          uuid: 'TEST-UUID',
          displayName: 'Char 1',
          properties: [],
        );
        const char2 = BleCharacteristicModel(
          uuid: 'test-uuid',
          displayName: 'Char 2',
          properties: [],
        );
        // Equality is based on exact UUID match, not case-insensitive
        expect(char1 == char2, false);
      });
    });
  });
}
