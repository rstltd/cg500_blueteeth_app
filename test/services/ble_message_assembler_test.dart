import 'package:cg500_blueteeth_app/services/ble_message_assembler.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BleMessageAssembler — line delimited', () {
    test('single message ending in \\n', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.addChunk('Hello\n'.codeUnits);
      expect(emitted, ['Hello']);
    });

    test('single message ending in \\r\\n', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.addChunk('Hello\r\n'.codeUnits);
      expect(emitted, ['Hello']);
    });

    test('two consecutive messages with \\n', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.addChunk('Line1\nLine2\n'.codeUnits);
      expect(emitted, ['Line1', 'Line2']);
    });

    test('two consecutive messages with \\r\\n', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.addChunk('Line1\r\nLine2\r\n'.codeUnits);
      expect(emitted, ['Line1', 'Line2']);
    });

    test('mixed \\n and \\r\\n delimiters', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.addChunk('A\nB\r\nC\n'.codeUnits);
      expect(emitted, ['A', 'B', 'C']);
    });

    test('empty lines between messages are skipped (decode-empty)', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.addChunk('A\n\nB\n'.codeUnits);
      // The empty line between A and B produces an empty string which is
      // dropped by _emitLine's isNotEmpty guard.
      expect(emitted, ['A', 'B']);
    });
  });

  group('BleMessageAssembler — cross-chunk assembly', () {
    test('message split across two chunks', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.addChunk('Hel'.codeUnits);
      expect(emitted, isEmpty);
      a.addChunk('lo\n'.codeUnits);
      expect(emitted, ['Hello']);
    });

    test('\\r\\n split across chunk boundary', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.addChunk('Hi\r'.codeUnits);
      expect(emitted, isEmpty);
      a.addChunk('\n'.codeUnits);
      expect(emitted, ['Hi']);
    });

    test('multi-line payload split awkwardly across chunks', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.addChunk('MAC: CN001\nVolt'.codeUnits);
      expect(emitted, ['MAC: CN001']);
      a.addChunk('age: 12.3\nIP: 1.2.3.4\n'.codeUnits);
      expect(emitted, ['MAC: CN001', 'Voltage: 12.3', 'IP: 1.2.3.4']);
    });
  });

  group('BleMessageAssembler — quiet timeout fallback', () {
    test('buffer without delimiter flushes after quietTimeout', () {
      FakeAsync().run((async) {
        final emitted = <String>[];
        final a = BleMessageAssembler(
          onMessage: emitted.add,
          quietTimeout: const Duration(milliseconds: 50),
        );
        a.addChunk('StreamingData'.codeUnits);
        expect(emitted, isEmpty);

        async.elapse(const Duration(milliseconds: 49));
        expect(emitted, isEmpty);

        async.elapse(const Duration(milliseconds: 2));
        expect(emitted, ['StreamingData']);
      });
    });

    test('new chunk before timeout resets the timer', () {
      FakeAsync().run((async) {
        final emitted = <String>[];
        final a = BleMessageAssembler(
          onMessage: emitted.add,
          quietTimeout: const Duration(milliseconds: 50),
        );
        a.addChunk('Part1'.codeUnits);
        async.elapse(const Duration(milliseconds: 40));
        a.addChunk('Part2'.codeUnits);
        async.elapse(const Duration(milliseconds: 40));
        expect(emitted, isEmpty);
        async.elapse(const Duration(milliseconds: 15));
        expect(emitted, ['Part1Part2']);
      });
    });

    test('line drain cancels pending timer when buffer empties', () {
      FakeAsync().run((async) {
        final emitted = <String>[];
        final a = BleMessageAssembler(
          onMessage: emitted.add,
          quietTimeout: const Duration(milliseconds: 50),
        );
        a.addChunk('A'.codeUnits);
        async.elapse(const Duration(milliseconds: 20));
        a.addChunk('\n'.codeUnits);
        expect(emitted, ['A']);
        // No pending timer should fire. Elapse well beyond quietTimeout.
        async.elapse(const Duration(milliseconds: 200));
        expect(emitted, ['A']);
      });
    });
  });

  group('BleMessageAssembler — overflow safety', () {
    test('buffer exceeding maxBufferSize force-flushes', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(
        onMessage: emitted.add,
        maxBufferSize: 8,
      );
      a.addChunk('0123456789'.codeUnits);
      // 10 bytes > 8 maxBufferSize → force flush
      expect(emitted, ['0123456789']);
    });
  });

  group('BleMessageAssembler — UTF-8 edge cases', () {
    test('multi-byte codepoint split across chunks produces U+FFFD then valid',
        () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      // "中" is E4 B8 AD in UTF-8. Split it so first chunk ends mid-codepoint.
      a.addChunk([0xE4]);
      // Buffer now has a partial codepoint. Next chunk completes it + \n
      a.addChunk([0xB8, 0xAD, 0x0A]);
      expect(emitted.length, 1);
      // The combined 3 bytes decode cleanly to "中".
      expect(emitted.single, '中');
    });

    test('malformed UTF-8 produces replacement char without throwing', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      // 0xFF is never a valid UTF-8 start byte.
      a.addChunk([0xFF, 0x0A]);
      expect(emitted.length, 1);
      expect(emitted.single, isNotEmpty);
    });
  });

  group('BleMessageAssembler — lifecycle', () {
    test('reset clears buffer and cancels pending timer', () {
      FakeAsync().run((async) {
        final emitted = <String>[];
        final a = BleMessageAssembler(
          onMessage: emitted.add,
          quietTimeout: const Duration(milliseconds: 50),
        );
        a.addChunk('partial'.codeUnits);
        a.reset();
        async.elapse(const Duration(milliseconds: 200));
        expect(emitted, isEmpty);
      });
    });

    test('addChunk after dispose is a no-op', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.dispose();
      a.addChunk('Hello\n'.codeUnits);
      expect(emitted, isEmpty);
    });

    test('dispose after buffered data does not emit', () {
      FakeAsync().run((async) {
        final emitted = <String>[];
        final a = BleMessageAssembler(
          onMessage: emitted.add,
          quietTimeout: const Duration(milliseconds: 50),
        );
        a.addChunk('pending'.codeUnits);
        a.dispose();
        async.elapse(const Duration(milliseconds: 200));
        expect(emitted, isEmpty);
      });
    });

    test('empty chunk is ignored', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.addChunk([]);
      expect(emitted, isEmpty);
    });
  });

  group('BleMessageAssembler — realistic device scenarios', () {
    test('\$INFO-style multi-line response in one chunk', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      const payload =
          'MAC: CN001\r\nVolt: 12.3V\r\nIP: 1.2.3.4\r\nPort: 8180\r\nTime: 2026-04-14\r\nFW: v1.0\r\n';
      a.addChunk(payload.codeUnits);
      expect(emitted, [
        'MAC: CN001',
        'Volt: 12.3V',
        'IP: 1.2.3.4',
        'Port: 8180',
        'Time: 2026-04-14',
        'FW: v1.0',
      ]);
    });

    test('\$INFO response fragmented across three BLE notifications', () {
      final emitted = <String>[];
      final a = BleMessageAssembler(onMessage: emitted.add);
      a.addChunk('MAC: CN001\r\nVolt: 12.3V\r\nIP: 1.2'.codeUnits);
      expect(emitted, ['MAC: CN001', 'Volt: 12.3V']);
      a.addChunk('.3.4\r\nPort: 8180\r'.codeUnits);
      expect(emitted, ['MAC: CN001', 'Volt: 12.3V', 'IP: 1.2.3.4']);
      a.addChunk('\nTime: 2026-04-14\r\n'.codeUnits);
      expect(emitted, [
        'MAC: CN001',
        'Volt: 12.3V',
        'IP: 1.2.3.4',
        'Port: 8180',
        'Time: 2026-04-14',
      ]);
    });

    test('\$DEBUG streaming GPS lines at high rate all emit via delimiter', () {
      FakeAsync().run((async) {
        final emitted = <String>[];
        final a = BleMessageAssembler(onMessage: emitted.add);
        for (var i = 0; i < 5; i++) {
          a.addChunk('GPS,25.0$i,121.5$i\n'.codeUnits);
          async.elapse(const Duration(milliseconds: 10));
        }
        expect(emitted.length, 5);
        expect(emitted.first, 'GPS,25.00,121.50');
        expect(emitted.last, 'GPS,25.04,121.54');
      });
    });
  });
}
