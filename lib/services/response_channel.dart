import 'dart:async';

import 'ble_message_assembler.dart';

/// Owns the "listen to a notify characteristic and reassemble its chunks"
/// pair — one [StreamSubscription] plus the [BleMessageAssembler] it feeds.
///
/// This exists because the pair was hand-rolled in four places in
/// `BleService`, and three separate bugs in this codebase have been the same
/// mistake: overwriting a `StreamSubscription` field without cancelling the
/// previous one. `flutter_blue_plus` hands out a NEW platform stream on every
/// `.listen()` call, so a leaked listener is not merely idle — every device
/// notification is then delivered once per leak, and the command interface
/// reacts N times to a single reply.
///
/// [attach] therefore always [detach]es first. That is the invariant the
/// tests in `test/services/response_channel_test.dart` pin down.
///
/// The class deliberately accepts a plain `Stream<List<int>>` rather than a
/// `BluetoothCharacteristic`: that keeps it free of `flutter_blue_plus`
/// types and therefore directly testable with a real [StreamController].
class ResponseChannel {
  StreamSubscription<List<int>>? _subscription;
  BleMessageAssembler? _assembler;

  /// True while a source stream is wired up. Exposed for tests and
  /// diagnostics; callers should not need to branch on it.
  bool get isAttached => _subscription != null;

  /// Listen to [source], feeding every chunk through a fresh
  /// [BleMessageAssembler] and handing each reassembled message to
  /// [onMessage].
  ///
  /// Any previously attached source is detached first, so calling this on
  /// reconnect or re-discovery cannot leave an orphaned listener behind.
  ///
  /// [onError] is optional on purpose: the Nordic UART path logs stream
  /// errors, while the generic fallback lets them reach the zone handler the
  /// same way it always has. Passing null is identical to not supplying an
  /// error handler to `Stream.listen`.
  Future<void> attach(
    Stream<List<int>> source, {
    required void Function(String message) onMessage,
    void Function(Object error)? onError,
  }) async {
    // Swap synchronously and await the old cancel afterwards. Calling
    // `detach()` here instead would yield before the new subscription is
    // installed, and a concurrent attach() — two Connect taps in quick
    // succession — would then see an empty channel, install its own listener,
    // and whichever assignment landed second would orphan the other. That is
    // the exact leak this class exists to prevent, so it must not be
    // reintroduced by the ordering inside attach() itself.
    final previousSubscription = _subscription;
    final previousAssembler = _assembler;

    final assembler = BleMessageAssembler(onMessage: onMessage);
    _assembler = assembler;
    // Bind to the local `assembler`, not the field: a chunk that arrives
    // between a future detach() and the cancel completing must not be able to
    // land in whatever assembler happens to occupy the field by then.
    _subscription = source.listen(assembler.addChunk, onError: onError);

    previousAssembler?.dispose();
    await previousSubscription?.cancel();
  }

  /// Cancel the current subscription and drop the assembler along with any
  /// partial message it still holds. Safe to call when nothing is attached
  /// and safe to call repeatedly.
  Future<void> detach() async {
    final subscription = _subscription;
    final assembler = _assembler;
    _subscription = null;
    _assembler = null;
    // Dispose synchronously, before awaiting the cancel: `dispose()` stops
    // the assembler's quiet timer, so a teardown can never be followed by a
    // stray flush of a half-received message.
    assembler?.dispose();
    await subscription?.cancel();
  }
}
