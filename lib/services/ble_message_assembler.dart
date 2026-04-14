import 'dart:async';
import 'dart:convert';

import '../utils/logger.dart';

/// Reassembles fragmented BLE notification chunks into complete messages.
///
/// Each BLE notification from the device is treated as a byte chunk. The
/// assembler buffers incoming chunks and emits complete messages via
/// [onMessage] using one of three strategies:
///
/// 1. **Line-delimited** — if the buffer contains `\r\n` or `\n`, every
///    complete line is emitted immediately. `\r\n` takes precedence when
///    both delimiters would match at the same position.
/// 2. **Quiet-timeout fallback** — if no delimiter is found, the remaining
///    buffer is flushed after [quietTimeout] elapses with no new chunks.
///    Handles streaming commands (e.g. `$DEBUG`) and devices that do not
///    line-terminate their responses.
/// 3. **Overflow safety** — if the buffer exceeds [maxBufferSize] bytes,
///    it is force-flushed to prevent unbounded growth.
///
/// UTF-8 decoding uses `allowMalformed: true`, so multi-byte codepoints
/// split across chunk boundaries surface as U+FFFD replacement characters
/// on the first chunk rather than throwing and losing data.
class BleMessageAssembler {
  BleMessageAssembler({
    required this.onMessage,
    this.quietTimeout = const Duration(milliseconds: 50),
    this.maxBufferSize = 4096,
  });

  final void Function(String message) onMessage;
  final Duration quietTimeout;
  final int maxBufferSize;

  final List<int> _buffer = [];
  Timer? _quietTimer;
  bool _disposed = false;

  /// Feed a BLE notification chunk into the assembler.
  void addChunk(List<int> chunk) {
    if (_disposed) return;
    if (chunk.isEmpty) return;

    _buffer.addAll(chunk);
    Logger.diagnostic(
      '[BLE_RAW] chunk len=${chunk.length} bufLen=${_buffer.length} hex=${_toHex(chunk)}',
    );

    _drainCompleteLines();

    if (_buffer.length > maxBufferSize) {
      Logger.warning(
        'BleMessageAssembler buffer exceeded $maxBufferSize bytes, force flushing',
      );
      flush();
      return;
    }

    if (_buffer.isNotEmpty) {
      _restartQuietTimer();
    } else {
      _quietTimer?.cancel();
      _quietTimer = null;
    }
  }

  /// Emit any remaining buffered bytes as a single message.
  void flush() {
    _quietTimer?.cancel();
    _quietTimer = null;
    if (_buffer.isEmpty) return;
    final message = _decode(_buffer);
    _buffer.clear();
    if (message.isNotEmpty) {
      onMessage(message);
    }
  }

  /// Discard buffered bytes and cancel the timer without emitting.
  /// Call on disconnect to drop in-flight partial messages.
  void reset() {
    _quietTimer?.cancel();
    _quietTimer = null;
    _buffer.clear();
  }

  /// Permanently disable the assembler. After calling [dispose],
  /// [addChunk] is a no-op. Safe to call multiple times.
  void dispose() {
    reset();
    _disposed = true;
  }

  void _drainCompleteLines() {
    var start = 0;
    var i = 0;
    while (i < _buffer.length) {
      final b = _buffer[i];
      if (b == 0x0D && i + 1 < _buffer.length && _buffer[i + 1] == 0x0A) {
        // \r\n
        final line = _buffer.sublist(start, i);
        _emitLine(line);
        i += 2;
        start = i;
      } else if (b == 0x0A) {
        // bare \n
        final line = _buffer.sublist(start, i);
        _emitLine(line);
        i += 1;
        start = i;
      } else {
        i += 1;
      }
    }
    if (start > 0) {
      _buffer.removeRange(0, start);
    }
  }

  void _emitLine(List<int> bytes) {
    // Strip a trailing lone \r (e.g. "abc\r" without following \n).
    // Rare in practice but keeps output clean.
    List<int> effective = bytes;
    if (effective.isNotEmpty && effective.last == 0x0D) {
      effective = effective.sublist(0, effective.length - 1);
    }
    final message = _decode(effective);
    if (message.isNotEmpty) {
      onMessage(message);
    }
  }

  void _restartQuietTimer() {
    _quietTimer?.cancel();
    _quietTimer = Timer(quietTimeout, () {
      if (_disposed) return;
      flush();
    });
  }

  String _decode(List<int> bytes) {
    return utf8.decode(bytes, allowMalformed: true);
  }

  String _toHex(List<int> bytes) {
    const max = 64;
    final display = bytes.length > max ? bytes.sublist(0, max) : bytes;
    final hex = display
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');
    return bytes.length > max ? '$hex ...(+${bytes.length - max})' : hex;
  }
}
