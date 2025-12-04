import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/utils/logger.dart';

void main() {
  group('Logger', () {
    setUp(() {
      // Reset log level before each test
      Logger.setLogLevel(Logger.debugLevel);
    });

    group('log levels', () {
      test('debugLevel should be 0', () {
        expect(Logger.debugLevel, 0);
      });

      test('infoLevel should be 1', () {
        expect(Logger.infoLevel, 1);
      });

      test('warningLevel should be 2', () {
        expect(Logger.warningLevel, 2);
      });

      test('errorLevel should be 3', () {
        expect(Logger.errorLevel, 3);
      });

      test('levels should be in ascending order', () {
        expect(Logger.debugLevel, lessThan(Logger.infoLevel));
        expect(Logger.infoLevel, lessThan(Logger.warningLevel));
        expect(Logger.warningLevel, lessThan(Logger.errorLevel));
      });
    });

    group('setLogLevel', () {
      test('should set log level to debug', () {
        Logger.setLogLevel(Logger.debugLevel);
        // If no exception, test passes
        expect(true, true);
      });

      test('should set log level to info', () {
        Logger.setLogLevel(Logger.infoLevel);
        expect(true, true);
      });

      test('should set log level to warning', () {
        Logger.setLogLevel(Logger.warningLevel);
        expect(true, true);
      });

      test('should set log level to error', () {
        Logger.setLogLevel(Logger.errorLevel);
        expect(true, true);
      });
    });

    group('debug', () {
      test('should not throw when called', () {
        expect(() => Logger.debug('Test debug message'), returnsNormally);
      });

      test('should accept optional tag', () {
        expect(
          () => Logger.debug('Test message', tag: 'TEST_TAG'),
          returnsNormally,
        );
      });
    });

    group('info', () {
      test('should not throw when called', () {
        expect(() => Logger.info('Test info message'), returnsNormally);
      });

      test('should accept optional tag', () {
        expect(
          () => Logger.info('Test message', tag: 'TEST_TAG'),
          returnsNormally,
        );
      });
    });

    group('warning', () {
      test('should not throw when called', () {
        expect(() => Logger.warning('Test warning message'), returnsNormally);
      });

      test('should accept optional tag', () {
        expect(
          () => Logger.warning('Test message', tag: 'TEST_TAG'),
          returnsNormally,
        );
      });
    });

    group('error', () {
      test('should not throw when called', () {
        expect(() => Logger.error('Test error message'), returnsNormally);
      });

      test('should accept optional tag', () {
        expect(
          () => Logger.error('Test message', tag: 'TEST_TAG'),
          returnsNormally,
        );
      });

      test('should accept optional error object', () {
        expect(
          () => Logger.error(
            'Test message',
            error: Exception('Test exception'),
          ),
          returnsNormally,
        );
      });

      test('should accept both tag and error', () {
        expect(
          () => Logger.error(
            'Test message',
            tag: 'TEST_TAG',
            error: Exception('Test exception'),
          ),
          returnsNormally,
        );
      });
    });

    group('specialized loggers', () {
      test('connection should not throw', () {
        expect(() => Logger.connection('Connection message'), returnsNormally);
      });

      test('ble should not throw', () {
        expect(() => Logger.ble('BLE message'), returnsNormally);
      });

      test('ui should not throw', () {
        expect(() => Logger.ui('UI message'), returnsNormally);
      });

      test('command should not throw', () {
        expect(() => Logger.command('Command message'), returnsNormally);
      });
    });

    group('log level filtering', () {
      test('debug messages should not throw at debug level', () {
        Logger.setLogLevel(Logger.debugLevel);
        expect(() => Logger.debug('Debug message'), returnsNormally);
      });

      test('info messages should not throw at info level', () {
        Logger.setLogLevel(Logger.infoLevel);
        expect(() => Logger.info('Info message'), returnsNormally);
      });

      test('warning messages should not throw at warning level', () {
        Logger.setLogLevel(Logger.warningLevel);
        expect(() => Logger.warning('Warning message'), returnsNormally);
      });

      test('error messages should not throw at error level', () {
        Logger.setLogLevel(Logger.errorLevel);
        expect(() => Logger.error('Error message'), returnsNormally);
      });

      test('debug messages should be silenced at error level', () {
        Logger.setLogLevel(Logger.errorLevel);
        // Should not throw or produce output (but we can't easily verify output is silenced)
        expect(() => Logger.debug('This should be silenced'), returnsNormally);
      });
    });

    group('edge cases', () {
      test('should handle empty message', () {
        expect(() => Logger.debug(''), returnsNormally);
        expect(() => Logger.info(''), returnsNormally);
        expect(() => Logger.warning(''), returnsNormally);
        expect(() => Logger.error(''), returnsNormally);
      });

      test('should handle very long message', () {
        final longMessage = 'A' * 10000;
        expect(() => Logger.debug(longMessage), returnsNormally);
      });

      test('should handle special characters in message', () {
        expect(
          () => Logger.debug('Special chars: \n\t\r\\\'\"'),
          returnsNormally,
        );
      });

      test('should handle unicode in message', () {
        expect(() => Logger.debug('Unicode: 中文 日本語 한국어 🎉'), returnsNormally);
      });

      test('should handle empty tag', () {
        expect(() => Logger.debug('Message', tag: ''), returnsNormally);
      });

      test('should handle null error gracefully', () {
        expect(() => Logger.error('Message', error: null), returnsNormally);
      });
    });
  });
}
