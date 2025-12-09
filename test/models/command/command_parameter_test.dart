import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/command/command_parameter.dart';
import 'package:cg500_blueteeth_app/models/command/parameter_type.dart';

void main() {
  group('CommandParameter', () {
    group('factory constructors', () {
      test('text() creates text parameter', () {
        final param = CommandParameter.text(
          id: 'test',
          label: 'Test Label',
          hint: 'Enter text',
        );

        expect(param.id, 'test');
        expect(param.label, 'Test Label');
        expect(param.type, ParameterType.text);
        expect(param.hint, 'Enter text');
        expect(param.required, true);
      });

      test('ipPort() creates IP:Port parameter', () {
        final param = CommandParameter.ipPort(
          id: 'addr',
          label: 'Address',
          defaultIp: '192.168.1.1',
          defaultPort: '8080',
        );

        expect(param.id, 'addr');
        expect(param.type, ParameterType.ipPort);
        expect(param.defaultValue, '192.168.1.1:8080');
      });

      test('number() creates number parameter with range', () {
        final param = CommandParameter.number(
          id: 'count',
          label: 'Count',
          min: 0,
          max: 100,
        );

        expect(param.type, ParameterType.number);
        expect(param.minValue, 0);
        expect(param.maxValue, 100);
      });

      test('hourPicker() creates hour picker parameter', () {
        final param = CommandParameter.hourPicker(
          id: 'hour',
          label: 'Hour',
          defaultHour: 2,
        );

        expect(param.type, ParameterType.hourPicker);
        expect(param.defaultValue, '2');
      });

      test('bitFlags() creates bit flags parameter', () {
        final flags = [
          const BitFlagOption(label: 'Option 1', value: 1),
          const BitFlagOption(label: 'Option 2', value: 2),
        ];

        final param = CommandParameter.bitFlags(
          id: 'flags',
          label: 'Flags',
          flags: flags,
          defaultValue: 3,
        );

        expect(param.type, ParameterType.bitFlags);
        expect(param.bitFlagOptions, flags);
        expect(param.defaultValue, '3');
      });
    });

    group('validate', () {
      group('required validation', () {
        test('returns error for empty required field', () {
          final param = CommandParameter.text(
            id: 'test',
            label: 'Test',
            required: true,
          );

          expect(param.validate(null), contains('必填'));
          expect(param.validate(''), contains('必填'));
        });

        test('returns null for empty optional field', () {
          final param = CommandParameter.text(
            id: 'test',
            label: 'Test',
            required: false,
          );

          expect(param.validate(null), isNull);
          expect(param.validate(''), isNull);
        });
      });

      group('text validation', () {
        test('accepts any non-empty text', () {
          final param = CommandParameter.text(id: 'test', label: 'Test');

          expect(param.validate('hello'), isNull);
          expect(param.validate('123'), isNull);
          expect(param.validate('a'), isNull);
        });
      });

      group('IP:Port validation', () {
        final param = CommandParameter.ipPort(id: 'addr', label: 'Address');

        test('accepts valid IP:Port', () {
          expect(param.validate('192.168.1.1:8080'), isNull);
          expect(param.validate('0.0.0.0:1'), isNull);
          expect(param.validate('255.255.255.255:65535'), isNull);
        });

        test('rejects invalid format', () {
          expect(param.validate('192.168.1.1'), isNotNull);
          expect(param.validate('192.168.1.1:'), isNotNull);
          expect(param.validate(':8080'), isNotNull);
        });

        test('rejects invalid IP', () {
          expect(param.validate('256.168.1.1:8080'), isNotNull);
          expect(param.validate('192.168.1:8080'), isNotNull);
          expect(param.validate('192.168.1.1.1:8080'), isNotNull);
        });

        test('rejects invalid port', () {
          expect(param.validate('192.168.1.1:0'), isNotNull);
          expect(param.validate('192.168.1.1:65536'), isNotNull);
          expect(param.validate('192.168.1.1:abc'), isNotNull);
        });
      });

      group('number validation', () {
        test('accepts valid numbers within range', () {
          final param = CommandParameter.number(
            id: 'num',
            label: 'Number',
            min: 0,
            max: 100,
          );

          expect(param.validate('0'), isNull);
          expect(param.validate('50'), isNull);
          expect(param.validate('100'), isNull);
        });

        test('rejects numbers outside range', () {
          final param = CommandParameter.number(
            id: 'num',
            label: 'Number',
            min: 0,
            max: 100,
          );

          expect(param.validate('-1'), isNotNull);
          expect(param.validate('101'), isNotNull);
        });

        test('rejects non-numeric values', () {
          final param = CommandParameter.number(id: 'num', label: 'Number');

          expect(param.validate('abc'), isNotNull);
          expect(param.validate('1.5'), isNotNull);
        });
      });

      group('hour validation', () {
        final param = CommandParameter.hourPicker(id: 'hour', label: 'Hour');

        test('accepts valid hours (0-23)', () {
          expect(param.validate('0'), isNull);
          expect(param.validate('12'), isNull);
          expect(param.validate('23'), isNull);
        });

        test('rejects invalid hours', () {
          expect(param.validate('-1'), isNotNull);
          expect(param.validate('24'), isNotNull);
          expect(param.validate('abc'), isNotNull);
        });
      });

      group('bitFlags validation', () {
        final param = CommandParameter.bitFlags(
          id: 'flags',
          label: 'Flags',
          flags: const [
            BitFlagOption(label: 'A', value: 1),
            BitFlagOption(label: 'B', value: 2),
            BitFlagOption(label: 'C', value: 4),
          ],
        );

        test('accepts valid flag combinations', () {
          expect(param.validate('0'), isNull);
          expect(param.validate('1'), isNull);
          expect(param.validate('3'), isNull);
          expect(param.validate('7'), isNull);
        });

        test('rejects values exceeding max', () {
          expect(param.validate('8'), isNotNull);
          expect(param.validate('15'), isNotNull);
        });

        test('rejects negative values', () {
          expect(param.validate('-1'), isNotNull);
        });

        test('rejects non-numeric values', () {
          expect(param.validate('abc'), isNotNull);
        });
      });
    });

    group('equality', () {
      test('parameters with same id are equal', () {
        final param1 = CommandParameter.text(id: 'test', label: 'Label 1');
        final param2 = CommandParameter.text(id: 'test', label: 'Label 2');

        expect(param1, equals(param2));
      });

      test('parameters with different id are not equal', () {
        final param1 = CommandParameter.text(id: 'test1', label: 'Label');
        final param2 = CommandParameter.text(id: 'test2', label: 'Label');

        expect(param1, isNot(equals(param2)));
      });
    });
  });

  group('BitFlagOption', () {
    test('creates with required fields', () {
      const option = BitFlagOption(label: 'Test', value: 1);

      expect(option.label, 'Test');
      expect(option.value, 1);
      expect(option.description, isNull);
    });

    test('creates with description', () {
      const option = BitFlagOption(
        label: 'Test',
        value: 1,
        description: 'Test description',
      );

      expect(option.description, 'Test description');
    });

    test('toString returns readable format', () {
      const option = BitFlagOption(label: 'Test', value: 1);

      expect(option.toString(), contains('Test'));
      expect(option.toString(), contains('1'));
    });
  });
}
