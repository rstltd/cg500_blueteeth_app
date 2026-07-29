import 'dart:async';

import '../controllers/ble_controller_interface.dart';
import '../l10n/app_strings.dart';
import '../models/ble_device.dart';
import '../models/connection_state.dart';
import '../utils/logger.dart';

/// What changed in the log, so listeners can react appropriately.
enum CommandLogChange {
  /// A message was appended to the end of the log.
  appended,

  /// The whole log was emptied.
  cleared,
}

/// App-wide chat log for the command interface.
///
/// Owns the list of [MessageData] rendered in the communication log, plus the
/// subscription to the BLE controller's response stream that feeds it.
///
/// **Why this is a singleton and not ViewModel state:**
/// `CommandInterfaceViewModel` is created and disposed by `ViewModelProvider`
/// together with its route, so anything it owns dies the moment the user
/// presses Back to the scanner — even though the BLE connection is still up.
/// The log has to outlive the route, so it lives here. Same shape as
/// [DeviceInfoTracker]: register once in the service locator, it subscribes on
/// construction, nothing else has to drive it.
///
/// **What clears the log:**
/// - The clear_all button (`CommandInterfaceViewModel.clearMessages`).
/// - Connecting to a *different* device id — a log describes one device, and
///   showing device A's lines under device B is worse than losing them.
///
/// **What must NOT clear the log:**
/// - Navigation of any kind. That is the entire reason this class exists.
/// - Disconnect, including transient drops and reconnects to the same device.
///   Unlike `DeviceInfoTracker`, which resets on disconnect because stale field
///   values would mis-seed the wizard form, the log is a record: the lines
///   received just before a drop are exactly what diagnoses the drop.
///
/// In memory only — an app restart loses the log, consistent with the
/// project's posture on session state (ADR-0005).
class CommandLogService {
  CommandLogService({required BleControllerInterface controller})
      : _controller = controller {
    _responseSubscription =
        _controller.commandResponseStream.listen(_onResponseLine);
    _connectionSubscription =
        _controller.connectedDeviceStream.listen(_onConnectionChanged);
  }

  final BleControllerInterface _controller;
  StreamSubscription<String>? _responseSubscription;
  StreamSubscription<BleDeviceModel?>? _connectionSubscription;

  final StreamController<CommandLogChange> _changeController =
      StreamController<CommandLogChange>.broadcast();

  final List<MessageData> _messages = [];
  String? _lastConnectedDeviceId;

  /// Upper bound on retained messages. The log now spans the whole app session
  /// rather than one route, and the device's $DEBUG output is a continuous
  /// stream, so the oldest entries are dropped instead of growing without
  /// bound. Mirrors the 20-item cap on `CommandManager` history.
  static const int maxMessages = 500;

  // Defense-in-depth dedup state: suppress near-simultaneous identical
  // response messages, which would otherwise slip through if any upstream
  // layer (e.g. an orphaned BLE subscription) double-emits.
  //
  // Known trade-off: `BleMessageAssembler._drainCompleteLines()` is a
  // synchronous while-loop, so every complete line in the same BLE chunk is
  // emitted within the same event-loop tick (0ms apart). That means two
  // genuinely-repeated response lines arriving in the *same* assembler drain
  // batch are indistinguishable from a double-emit here and get merged into
  // one — this window cannot tell them apart by time alone. We accept that
  // cost to keep double-emits from an orphaned subscription out of the log;
  // if faithful line-by-line recording ever becomes a requirement, this
  // needs a sequence-number-based dedup instead of a time window.
  MessageData? _lastResponseMessage;
  DateTime? _lastResponseAt;
  static const Duration responseDedupWindow = Duration(milliseconds: 50);

  /// Every message currently in the log, oldest first.
  List<MessageData> get messages => List.unmodifiable(_messages);

  /// Emits after every append and every clear.
  Stream<CommandLogChange> get changeStream => _changeController.stream;

  /// Append a message to the log.
  ///
  /// Near-simultaneous duplicate *responses* are dropped; commands are never
  /// deduped, so two identical user commands both stay visible.
  void add(MessageData message) {
    if (!message.isCommand &&
        _lastResponseMessage != null &&
        _lastResponseAt != null &&
        _lastResponseMessage!.text == message.text &&
        DateTime.now().difference(_lastResponseAt!) < responseDedupWindow) {
      Logger.diagnostic(
        '[DEDUP] Suppressed near-simultaneous duplicate response: ${message.text}',
      );
      return;
    }
    if (!message.isCommand) {
      _lastResponseMessage = message;
      _lastResponseAt = DateTime.now();
    }

    _messages.add(message);
    if (_messages.length > maxMessages) {
      _messages.removeRange(0, _messages.length - maxMessages);
    }
    _changeController.add(CommandLogChange.appended);
  }

  /// Empty the log. Only the clear_all button and a new-device connection may
  /// call this — see the class doc for what must NOT clear it.
  void clear() {
    if (_messages.isEmpty) return;
    _messages.clear();
    _lastResponseMessage = null;
    _lastResponseAt = null;
    _changeController.add(CommandLogChange.cleared);
  }

  void _onResponseLine(String line) {
    add(MessageData(
      text: _sanitizeUndecodableText(line),
      isCommand: false,
      timestamp: DateTime.now(),
    ));
  }

  /// Collapse a long run of U+FFFD replacement characters into an honest
  /// placeholder. Those come from `BleMessageAssembler`'s allowMalformed UTF-8
  /// decode when the firmware sends raw bytes for a field — a factory-fresh
  /// device reports an unset Gateway as ~30 undecodable bytes, which rendered
  /// as a wall of glyphs.
  ///
  /// The threshold is deliberately 4, not 1: an isolated one- or two-character
  /// corruption is a *symptom worth seeing* (a single ASCII byte damaged in
  /// transit becomes exactly one U+FFFD), and hiding it would erase the only
  /// visible evidence of link-layer corruption. Valid UTF-8 never contains
  /// U+FFFD, so this can never suppress legitimate data.
  String _sanitizeUndecodableText(String text) {
    if (!text.contains('�')) return text;
    return text.replaceAll(
      RegExp('�{4,}'),
      AppStrings.undecodableResponseField,
    );
  }

  void _onConnectionChanged(BleDeviceModel? device) {
    // Disconnects never clear — a transient drop must not destroy the record.
    if (device == null || !device.connectionState.isConnected) return;

    if (_lastConnectedDeviceId != null &&
        _lastConnectedDeviceId != device.id) {
      clear();
    }
    _lastConnectedDeviceId = device.id;
  }

  void dispose() {
    _responseSubscription?.cancel();
    _connectionSubscription?.cancel();
    _changeController.close();
  }
}

/// Immutable data class for a message.
class MessageData {
  const MessageData({
    required this.text,
    required this.isCommand,
    required this.timestamp,
    this.isError = false,
  });

  /// Create from a Map (for compatibility with existing code).
  factory MessageData.fromMap(Map<String, dynamic> map) {
    return MessageData(
      text: map['text'] as String? ?? '',
      isCommand: map['isCommand'] as bool? ?? false,
      timestamp: map['timestamp'] as DateTime? ?? DateTime.now(),
      isError: map['isError'] as bool? ?? false,
    );
  }

  final String text;
  final bool isCommand;
  final DateTime timestamp;
  final bool isError;

  /// Convert to Map for compatibility with existing widgets.
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isCommand': isCommand,
      'timestamp': timestamp,
      'isError': isError,
    };
  }
}
