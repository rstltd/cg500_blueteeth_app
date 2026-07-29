import 'dart:async';

import 'package:cg500_blueteeth_app/services/response_channel.dart';
import 'package:flutter_test/flutter_test.dart';

/// The assembler's quiet-timeout fallback is 50ms; anything longer than that
/// is enough to prove a flush did or did not happen.
const _pastQuietTimeout = Duration(milliseconds: 150);

void main() {
  group('ResponseChannel — the re-attach invariant', () {
    test('attach cancels the previous subscription', () async {
      final first = StreamController<List<int>>();
      final second = StreamController<List<int>>();
      addTearDown(first.close);
      addTearDown(second.close);

      final channel = ResponseChannel();
      addTearDown(channel.detach);

      await channel.attach(first.stream, onMessage: (_) {});
      expect(first.hasListener, isTrue);

      await channel.attach(second.stream, onMessage: (_) {});

      // This is the invariant three separate bugs in this codebase have
      // broken: overwriting the subscription field without cancelling first
      // leaves the old platform listener alive, so every device notification
      // is delivered once per leaked listener.
      expect(first.hasListener, isFalse);
      expect(second.hasListener, isTrue);
    });

    test('concurrent attaches cannot orphan a listener', () async {
      final first = StreamController<List<int>>.broadcast();
      final second = StreamController<List<int>>.broadcast();
      addTearDown(first.close);
      addTearDown(second.close);

      final channel = ResponseChannel();
      addTearDown(channel.detach);

      await channel.attach(first.stream, onMessage: (_) {});

      // Two Connect taps in quick succession: the second attach starts before
      // the first has finished. If attach() yielded before installing its own
      // subscription, both calls would see an empty channel and whichever
      // assignment landed second would orphan the other listener — the exact
      // leak this class exists to prevent, reintroduced from the inside.
      final third = StreamController<List<int>>.broadcast();
      addTearDown(third.close);
      final pending = <Future<void>>[
        channel.attach(second.stream, onMessage: (_) {}),
        channel.attach(third.stream, onMessage: (_) {}),
      ];
      await Future.wait(pending);
      await _settle();

      expect(first.hasListener, isFalse);
      expect(second.hasListener, isFalse,
          reason: 'the intermediate source must not keep a live listener');
      expect(third.hasListener, isTrue);
    });

    test('a leaked listener would double-deliver; it does not', () async {
      final first = StreamController<List<int>>.broadcast();
      final second = StreamController<List<int>>.broadcast();
      addTearDown(first.close);
      addTearDown(second.close);

      final messages = <String>[];
      final channel = ResponseChannel();
      addTearDown(channel.detach);

      await channel.attach(first.stream, onMessage: messages.add);
      await channel.attach(second.stream, onMessage: messages.add);

      // A broadcast controller accepts adds with no listener, so this only
      // stays silent if the first subscription was really cancelled.
      first.add('stale\r\n'.codeUnits);
      second.add('fresh\r\n'.codeUnits);
      await _settle();

      expect(messages, ['fresh']);
    });

    test('re-attaching starts a clean assembler, not a shared buffer',
        () async {
      final first = StreamController<List<int>>();
      final second = StreamController<List<int>>();
      addTearDown(first.close);
      addTearDown(second.close);

      final messages = <String>[];
      final channel = ResponseChannel();
      addTearDown(channel.detach);

      await channel.attach(first.stream, onMessage: messages.add);
      // Half a line: no delimiter, so it sits in the old assembler's buffer.
      first.add('PARTI'.codeUnits);
      await _settle();
      expect(messages, isEmpty);

      await channel.attach(second.stream, onMessage: messages.add);
      second.add('AL\r\n'.codeUnits);
      await _settle();

      // The stranded 'PARTI' must not be glued onto the front of the new
      // channel's first reply.
      expect(messages, ['AL']);

      // And it must never surface later via the old assembler's quiet timer.
      await Future<void>.delayed(_pastQuietTimeout);
      expect(messages, ['AL']);
    });

    test('isAttached reflects attach/detach', () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);

      final channel = ResponseChannel();
      expect(channel.isAttached, isFalse);

      await channel.attach(source.stream, onMessage: (_) {});
      expect(channel.isAttached, isTrue);

      await channel.detach();
      expect(channel.isAttached, isFalse);
    });
  });

  group('ResponseChannel — detach', () {
    test('stops delivering messages and releases the listener', () async {
      final source = StreamController<List<int>>.broadcast();
      addTearDown(source.close);

      final messages = <String>[];
      final channel = ResponseChannel();

      await channel.attach(source.stream, onMessage: messages.add);
      source.add('before\r\n'.codeUnits);
      await _settle();
      expect(messages, ['before']);

      await channel.detach();
      expect(source.hasListener, isFalse);

      source.add('after\r\n'.codeUnits);
      await _settle();
      expect(messages, ['before']);
    });

    test('drops a half-received message instead of flushing it later',
        () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);

      final messages = <String>[];
      final channel = ResponseChannel();

      await channel.attach(source.stream, onMessage: messages.add);
      // No delimiter: the assembler holds this and arms its quiet timer.
      source.add('half a reply'.codeUnits);
      await _settle();
      expect(messages, isEmpty);

      await channel.detach();

      // detach() disposes the assembler, which cancels that timer. Without
      // it the partial line would arrive ~50ms after teardown, on a channel
      // whose device is already gone.
      await Future<void>.delayed(_pastQuietTimeout);
      expect(messages, isEmpty);
    });

    test('is safe to call twice, and safe with nothing attached', () async {
      final channel = ResponseChannel();

      // Never attached.
      await channel.detach();

      final source = StreamController<List<int>>();
      addTearDown(source.close);
      await channel.attach(source.stream, onMessage: (_) {});

      await channel.detach();
      await channel.detach();

      expect(channel.isAttached, isFalse);
      expect(source.hasListener, isFalse);
    });
  });

  group('ResponseChannel — message assembly', () {
    test('reassembles a line split across chunks', () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);

      final messages = <String>[];
      final channel = ResponseChannel();
      addTearDown(channel.detach);

      await channel.attach(source.stream, onMessage: messages.add);

      source.add('\$INFO,'.codeUnits);
      source.add('CG500'.codeUnits);
      source.add(',v1\r\n'.codeUnits);
      await _settle();

      expect(messages, [r'$INFO,CG500,v1']);
    });

    test('emits one message per line when several arrive in one chunk',
        () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);

      final messages = <String>[];
      final channel = ResponseChannel();
      addTearDown(channel.detach);

      await channel.attach(source.stream, onMessage: messages.add);
      source.add('A\r\nB\r\nC\r\n'.codeUnits);
      await _settle();

      expect(messages, ['A', 'B', 'C']);
    });

    test('flushes an undelimited tail after the quiet timeout', () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);

      final messages = <String>[];
      final channel = ResponseChannel();
      addTearDown(channel.detach);

      await channel.attach(source.stream, onMessage: messages.add);
      source.add('no delimiter here'.codeUnits);
      await _settle();
      expect(messages, isEmpty);

      await Future<void>.delayed(_pastQuietTimeout);
      expect(messages, ['no delimiter here']);
    });
  });

  group('ResponseChannel — error handling', () {
    test('forwards stream errors to onError when one is supplied', () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);

      final errors = <Object>[];
      final messages = <String>[];
      final channel = ResponseChannel();
      addTearDown(channel.detach);

      await channel.attach(
        source.stream,
        onMessage: messages.add,
        onError: errors.add,
      );

      source.addError(StateError('platform notification failure'));
      await _settle();

      expect(errors, hasLength(1));
      expect(errors.single, isStateError);
      expect(messages, isEmpty);

      // The channel stays usable — an error is not a teardown.
      source.add('still alive\r\n'.codeUnits);
      await _settle();
      expect(messages, ['still alive']);
    });

    test('omitting onError leaves errors to the zone, as the generic '
        'fallback path relies on', () async {
      final source = StreamController<List<int>>();
      addTearDown(source.close);

      final channel = ResponseChannel();
      addTearDown(channel.detach);

      final zoneErrors = <Object>[];
      await runZonedGuarded(
        () async {
          // listen() is called inside this zone, so an unhandled stream error
          // is reported here rather than being swallowed.
          await channel.attach(source.stream, onMessage: (_) {});
          source.addError(StateError('platform notification failure'));
          await _settle();
        },
        (error, stack) => zoneErrors.add(error),
      );

      expect(zoneErrors, hasLength(1));
      expect(zoneErrors.single, isStateError);
    });
  });
}

/// Let the stream deliver everything queued so far. Delivery is asynchronous
/// even for a synchronously-added event, so assertions need one turn of the
/// event loop first.
Future<void> _settle() => Future<void>.delayed(Duration.zero);
