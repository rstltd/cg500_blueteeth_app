import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
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

      test('hostPort() creates Host:Port parameter with IP', () {
        final param = CommandParameter.hostPort(
          id: 'addr',
          label: 'Address',
          defaultHost: '192.168.1.1',
          defaultPort: '8080',
        );

        expect(param.id, 'addr');
        expect(param.type, ParameterType.hostPort);
        expect(param.defaultValue, '192.168.1.1:8080');
      });

      test('hostPort() creates Host:Port parameter with domain', () {
        final param = CommandParameter.hostPort(
          id: 'addr',
          label: 'Address',
          defaultHost: 'rmdgnss.com',
          defaultPort: '8180',
        );

        expect(param.id, 'addr');
        expect(param.type, ParameterType.hostPort);
        expect(param.defaultValue, 'rmdgnss.com:8180');
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

      test('dropdown() creates dropdown parameter', () {
        final options = [
          const DropdownOption(label: 'Option A', value: 'a'),
          const DropdownOption(label: 'Option B', value: 'b'),
        ];

        final param = CommandParameter.dropdown(
          id: 'choice',
          label: 'Choice',
          dropdownOptions: options,
          defaultValue: 'a',
        );

        expect(param.type, ParameterType.dropdown);
        expect(param.dropdownOptions, options);
        expect(param.defaultValue, 'a');
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

          expect(param.validate(null), AppStrings.requiredField('Test'));
          expect(param.validate(''), AppStrings.requiredField('Test'));
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

        test('rejects values containing a comma', () {
          final param = CommandParameter.text(id: 'test', label: 'Test');

          expect(
            param.validate('foo,bar'),
            AppStrings.textParameterContainsDelimiter,
          );
        });

        test('rejects values containing CR or LF', () {
          final param = CommandParameter.text(id: 'test', label: 'Test');

          expect(
            param.validate('foo\rbar'),
            AppStrings.textParameterContainsDelimiter,
          );
          expect(
            param.validate('foo\nbar'),
            AppStrings.textParameterContainsDelimiter,
          );
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

      group('Host:Port validation', () {
        final param = CommandParameter.hostPort(id: 'addr', label: 'Address');

        // Regression cover for F-003: ":9000" (host cleared, port still set)
        // put the colon at index 0, and the old `colonIndex > 0` test sent the
        // whole string down the host branch, reporting a domain-format error
        // for what is really an empty required host.
        test('empty host with a valid port reports a host error, not a domain-format one', () {
          final err = param.validate(':9000');
          expect(err, isNotNull);
          expect(err, isNot(contains('網域名稱格式錯誤')));
          expect(err, contains('主機位址'));
        });

        test('validateHostPortParts attributes each error to its own field', () {
          final emptyHost = param.validateHostPortParts(':9000');
          expect(emptyHost.host, isNotNull);
          expect(emptyHost.port, isNull, reason: '9000 is a valid port');

          final badPort = param.validateHostPortParts('example.com:0');
          expect(badPort.host, isNull, reason: 'example.com is a valid domain');
          expect(badPort.port, isNotNull);

          final bothOk = param.validateHostPortParts('example.com:9000');
          expect(bothOk.host, isNull);
          expect(bothOk.port, isNull);
        });

        test('accepts valid IP:Port', () {
          expect(param.validate('192.168.1.1:8080'), isNull);
          expect(param.validate('0.0.0.0:1'), isNull);
          expect(param.validate('255.255.255.255:65535'), isNull);
        });

        test('accepts valid domain:Port', () {
          expect(param.validate('rmdgnss.com:8180'), isNull);
          expect(param.validate('example.com:80'), isNull);
          expect(param.validate('sub.domain.example.com:443'), isNull);
        });

        test('rejects missing port', () {
          // Device requires explicit port — host-only values are invalid
          // at the model level (the widget auto-fills 80 before submitting)
          expect(param.validate('192.168.1.1'), isNotNull);
          expect(param.validate('example.com'), isNotNull);
        });

        test('rejects invalid format', () {
          expect(param.validate(':8080'), isNotNull);
        });

        test('rejects invalid IP', () {
          expect(param.validate('256.168.1.1:8080'), isNotNull);
          expect(param.validate('192.168.1:8080'), isNotNull);
          expect(param.validate('192.168.1.1.1:8080'), isNotNull);
        });

        test('rejects invalid domain', () {
          expect(param.validate('nodot:8080'), isNotNull); // No dot in domain
        });

        test('rejects http/https prefix', () {
          expect(param.validate('http://example.com:8080'), isNotNull);
          expect(param.validate('https://example.com:8080'), isNotNull);
        });

        test('rejects invalid port', () {
          expect(param.validate('example.com:0'), isNotNull);
          expect(param.validate('example.com:65536'), isNotNull);
          expect(param.validate('example.com:abc'), isNotNull);
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

      group('dropdown validation', () {
        final param = CommandParameter.dropdown(
          id: 'apn',
          label: 'APN',
          dropdownOptions: const [
            DropdownOption(label: 'General SIM', value: 'internet'),
            DropdownOption(label: 'IoT SIM', value: 'internet.iot'),
          ],
        );

        test('accepts valid dropdown option values', () {
          expect(param.validate('internet'), isNull);
          expect(param.validate('internet.iot'), isNull);
        });

        test('rejects values not in options list', () {
          expect(param.validate('invalid'), isNotNull);
          expect(param.validate('other.apn'), isNotNull);
          expect(param.validate(''), isNotNull); // required field
        });

        test('accepts any value when no options defined', () {
          final emptyParam = CommandParameter(
            id: 'empty',
            label: 'Empty',
            type: ParameterType.dropdown,
            required: false,
          );
          expect(emptyParam.validate('anything'), isNull);
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
