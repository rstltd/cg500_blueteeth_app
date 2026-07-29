import 'package:cg500_blueteeth_app/models/device_info.dart';
import 'package:cg500_blueteeth_app/services/info_parser_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InfoParserService.updateFromLine — ADDR / FTPADDR mutual exclusion',
      () {
    // FTPADDR contains the substring "ADDR" — a naive implementation that
    // checks the two patterns independently (instead of "ftpAddr wins, then
    // only check addr if ftpAddr didn't match") would fill both fields from
    // a single FTPADDR line.
    test('FTPADDR line fills only ftpAddr, leaves addr null', () {
      final result =
          InfoParserService.updateFromLine(const DeviceInfo(), 'FTPADDR:1.2.3.4');

      expect(result.ftpAddr, '1.2.3.4');
      expect(result.addr, isNull);
    });

    test('Target Addr line fills only addr, leaves ftpAddr null', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'Target Addr: 1.2.3.4:9000',
      );

      expect(result.addr, '1.2.3.4:9000');
      expect(result.ftpAddr, isNull);
    });

    test('standalone ADDR line fills addr', () {
      final result =
          InfoParserService.updateFromLine(const DeviceInfo(), 'ADDR:5.6.7.8:8180');

      expect(result.addr, '5.6.7.8:8180');
      expect(result.ftpAddr, isNull);
    });

    test('"FTP ADDR" (with space) is still recognized as ftpAddr, not addr',
        () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'FTP ADDR:211.72.53.102:80',
      );

      expect(result.ftpAddr, '211.72.53.102:80');
      expect(result.addr, isNull);
    });

    test('"Prog Address" line is recognized as ftpAddr', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'Prog Address:211.72.53.102:80',
      );

      expect(result.ftpAddr, '211.72.53.102:80');
      expect(result.addr, isNull);
    });

    test(
        'a prior FTPADDR value survives a later Target Addr line, and vice '
        'versa (each line only ever touches its own field)', () {
      var info = const DeviceInfo();
      info = InfoParserService.updateFromLine(info, 'FTPADDR:1.2.3.4:80');
      info = InfoParserService.updateFromLine(
        info,
        'Target Addr: 5.6.7.8:9000',
      );

      expect(info.ftpAddr, '1.2.3.4:80');
      expect(info.addr, '5.6.7.8:9000');
    });

    test('"Command Addr" (not "Target Addr", not start-of-line "ADDR") does '
        'not match the addr pattern', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'Command Addr: 1.2.3.4',
      );

      expect(result.addr, isNull);
      expect(result.ftpAddr, isNull);
      expect(result, same(const DeviceInfo()));
    });
  });

  group('InfoParserService.updateFromLine — firmware pattern', () {
    test('FW:VALUE', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'FW:CG500-v1.2.3',
      );
      expect(result.firmwareName, 'CG500-v1.2.3');
    });

    test('FW=VALUE (equals separator)', () {
      final result =
          InfoParserService.updateFromLine(const DeviceInfo(), 'FW=1.0.0');
      expect(result.firmwareName, '1.0.0');
    });

    test('"Firmware name:" long form', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'Firmware name: CG500-v2.0.0',
      );
      expect(result.firmwareName, 'CG500-v2.0.0');
    });

    test('lower-case "fw:" still matches (case-insensitive)', () {
      final result =
          InfoParserService.updateFromLine(const DeviceInfo(), 'fw:1.2.3');
      expect(result.firmwareName, '1.2.3');
    });
  });

  group('InfoParserService.updateFromLine — APN pattern', () {
    test('APN:VALUE', () {
      final result =
          InfoParserService.updateFromLine(const DeviceInfo(), 'APN:internet');
      expect(result.apn, 'internet');
    });

    test('APN with a dotted IoT value', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'APN: internet.iot',
      );
      expect(result.apn, 'internet.iot');
    });

    test('APN value is a single non-whitespace token — trailing words after '
        'a space are not captured', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'APN: internet extra',
      );
      expect(result.apn, 'internet');
    });
  });

  group('InfoParserService.updateFromLine — IMEI pattern', () {
    test('IMEI:VALUE with a plausible 15-digit IMEI', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'IMEI:356938035643809',
      );
      expect(result.imei, '356938035643809');
    });

    test('IMEI value too short (<10 digits) is rejected, not stored', () {
      final result =
          InfoParserService.updateFromLine(const DeviceInfo(), 'IMEI:12345');
      expect(result.imei, isNull);
      expect(result, same(const DeviceInfo()));
    });

    test('non-numeric IMEI value is rejected, not stored', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'IMEI:not-a-number',
      );
      expect(result.imei, isNull);
      expect(result, same(const DeviceInfo()));
    });
  });

  group('InfoParserService.updateFromLine — REBOOT pattern', () {
    test('REBOOT:VALUE', () {
      final result =
          InfoParserService.updateFromLine(const DeviceInfo(), 'REBOOT:6');
      expect(result.rebootHour, '6');
    });

    test('"Reset hour:" long form', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'Reset hour: 14',
      );
      expect(result.rebootHour, '14');
    });

    test('REBOOT with no digit value is rejected, not stored', () {
      final result =
          InfoParserService.updateFromLine(const DeviceInfo(), 'REBOOT:');
      expect(result.rebootHour, isNull);
      expect(result, same(const DeviceInfo()));
    });
  });

  group('InfoParserService.updateFromLine — malformed / unexpected input', () {
    test('empty line returns the original instance unchanged', () {
      const current = DeviceInfo(firmwareName: 'CG500-v1.2.3');
      final result = InfoParserService.updateFromLine(current, '');
      expect(result, same(current));
    });

    test('a whitespace-only line returns the original instance unchanged',
        () {
      const current = DeviceInfo(apn: 'internet');
      final result = InfoParserService.updateFromLine(current, '   ');
      expect(result, same(current));
    });

    test('a line that is only a delimiter (":") returns the original '
        'instance unchanged', () {
      const current = DeviceInfo();
      final result = InfoParserService.updateFromLine(current, ':');
      expect(result, same(current));
    });

    test('an unrecognized noise line ("OK") returns the original instance '
        'unchanged, without throwing', () {
      const current = DeviceInfo();
      expect(
        () => InfoParserService.updateFromLine(current, 'OK'),
        returnsNormally,
      );
      final result = InfoParserService.updateFromLine(current, 'OK');
      expect(result, same(current));
    });

    test('a value containing unexpected symbols is captured verbatim rather '
        'than throwing or being dropped', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        r'APN:!!!@@@$$$',
      );
      expect(result.apn, r'!!!@@@$$$');
    });

    test('surrounding whitespace on the whole line is trimmed before '
        'matching', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        '   FW:CG500-v1.2.3   ',
      );
      expect(result.firmwareName, 'CG500-v1.2.3');
    });

    test('a tab between the separator and the value is tolerated', () {
      final result = InfoParserService.updateFromLine(
        const DeviceInfo(),
        'APN:\tinternet',
      );
      expect(result.apn, 'internet');
    });
  });

  group('InfoParserService.updateFromLine — accumulation across lines', () {
    test('fields already parsed survive unrelated subsequent lines', () {
      var info = const DeviceInfo();
      info = InfoParserService.updateFromLine(info, 'FW:CG500-v1.2.3');
      info = InfoParserService.updateFromLine(info, 'APN:internet');
      info = InfoParserService.updateFromLine(info, 'OK');

      expect(info.firmwareName, 'CG500-v1.2.3');
      expect(info.apn, 'internet');
    });

    test('a later line for the same field overwrites the earlier value '
        '(last-wins)', () {
      var info = const DeviceInfo();
      info = InfoParserService.updateFromLine(info, 'APN:internet');
      info = InfoParserService.updateFromLine(info, 'APN:internet2');

      expect(info.apn, 'internet2');
    });

    test('accumulating FW, APN, ADDR, FTPADDR, REBOOT and IMEI from '
        'separate lines never clears an already-populated field', () {
      var info = const DeviceInfo();
      info = InfoParserService.updateFromLine(info, 'FW:CG500-v1.2.3');
      info = InfoParserService.updateFromLine(info, 'APN:internet');
      info = InfoParserService.updateFromLine(info, 'Target Addr: 1.2.3.4:9000');
      info = InfoParserService.updateFromLine(info, 'FTPADDR:5.6.7.8:80');
      info = InfoParserService.updateFromLine(info, 'REBOOT:6');
      info = InfoParserService.updateFromLine(info, 'IMEI:356938035643809');

      expect(info.firmwareName, 'CG500-v1.2.3');
      expect(info.apn, 'internet');
      expect(info.addr, '1.2.3.4:9000');
      expect(info.ftpAddr, '5.6.7.8:80');
      expect(info.rebootHour, '6');
      expect(info.imei, '356938035643809');
    });
  });
}
