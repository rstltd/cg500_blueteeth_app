import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/command/custom_command.dart';
import '../utils/logger.dart';

/// Result of attempting to add or update a custom command.
enum CustomCommandResult {
  /// Operation succeeded and the change was persisted.
  success,

  /// Command string is empty or does not start with `$`.
  invalidFormat,

  /// Name is empty.
  nameRequired,

  /// Command string collides with another custom command.
  duplicateInCustom,

  /// Command string collides with a built-in command.
  duplicateInBuiltIn,

  /// The command being edited (old key) does not exist.
  notFound,
}

/// Persists and manages user-defined custom BLE commands.
///
/// - Stores a JSON array of [CustomCommand]s in SharedPreferences under
///   a single versioned key (`custom_commands_v1`). The key version makes
///   future schema migrations (e.g. adding parameters) straightforward.
/// - Emits the full current list on every mutation via [changeStream],
///   so repositories and view models can refresh reactively.
/// - Duplicate detection against built-in commands is deferred to the
///   caller via an `isBuiltIn` lambda, so this service stays free of
///   circular dependencies on any repository.
class CustomCommandService {
  CustomCommandService();

  static const String _prefsKey = 'custom_commands_v1';

  final StreamController<List<CustomCommand>> _changeController =
      StreamController<List<CustomCommand>>.broadcast();

  List<CustomCommand> _commands = const [];
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Load persisted commands from SharedPreferences. Safe to call
  /// multiple times; subsequent calls are no-ops.
  Future<void> initialize() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _commands = decoded
              .whereType<Map<String, dynamic>>()
              .map(CustomCommand.fromJson)
              .toList(growable: false);
        }
      } catch (e) {
        Logger.error('Failed to parse custom_commands_v1 from prefs', error: e);
        _commands = const [];
      }
    }
    _initialized = true;
  }

  /// Snapshot of the current custom command list.
  List<CustomCommand> list() => List.unmodifiable(_commands);

  /// Broadcast of the full list after every mutation.
  Stream<List<CustomCommand>> get changeStream => _changeController.stream;

  /// Add a new custom command. The [isBuiltIn] lambda is used to detect
  /// collisions with built-in commands without creating a repository
  /// dependency.
  Future<CustomCommandResult> add(
    CustomCommand cmd, {
    required bool Function(String normalizedKey) isBuiltIn,
  }) async {
    final validation = _validate(cmd);
    if (validation != null) return validation;

    final key = cmd.normalizedKey;
    if (_commands.any((c) => c.normalizedKey == key)) {
      return CustomCommandResult.duplicateInCustom;
    }
    if (isBuiltIn(key)) {
      return CustomCommandResult.duplicateInBuiltIn;
    }

    _commands = [..._commands, cmd];
    await _persist();
    _changeController.add(list());
    return CustomCommandResult.success;
  }

  /// Update an existing custom command keyed by [oldCommandStr].
  /// The command string itself may change; collisions with other
  /// custom commands or built-ins are still enforced.
  Future<CustomCommandResult> update(
    String oldCommandStr,
    CustomCommand updated, {
    required bool Function(String normalizedKey) isBuiltIn,
  }) async {
    final validation = _validate(updated);
    if (validation != null) return validation;

    final oldKey = oldCommandStr.trim().toUpperCase();
    final index = _commands.indexWhere((c) => c.normalizedKey == oldKey);
    if (index < 0) return CustomCommandResult.notFound;

    final newKey = updated.normalizedKey;
    if (newKey != oldKey) {
      if (_commands.any(
        (c) => c.normalizedKey == newKey && c.normalizedKey != oldKey,
      )) {
        return CustomCommandResult.duplicateInCustom;
      }
      if (isBuiltIn(newKey)) {
        return CustomCommandResult.duplicateInBuiltIn;
      }
    }

    final next = [..._commands];
    next[index] = updated;
    _commands = next;
    await _persist();
    _changeController.add(list());
    return CustomCommandResult.success;
  }

  /// Remove the custom command whose normalized key matches.
  Future<void> remove(String commandStr) async {
    final key = commandStr.trim().toUpperCase();
    final next =
        _commands.where((c) => c.normalizedKey != key).toList(growable: false);
    if (next.length == _commands.length) return;
    _commands = next;
    await _persist();
    _changeController.add(list());
  }

  /// Return any custom commands whose normalized key collides with an
  /// existing built-in command. Use [isBuiltIn] to query the built-in
  /// repository. Typically invoked when opening the management view so
  /// the user can resolve conflicts introduced by an app update.
  List<CustomCommand> detectConflicts({
    required bool Function(String normalizedKey) isBuiltIn,
  }) =>
      _commands.where((c) => isBuiltIn(c.normalizedKey)).toList(growable: false);

  void dispose() {
    _changeController.close();
  }

  CustomCommandResult? _validate(CustomCommand cmd) {
    final trimmed = cmd.command.trim();
    if (trimmed.isEmpty) return CustomCommandResult.invalidFormat;
    if (!trimmed.startsWith(r'$')) return CustomCommandResult.invalidFormat;
    if (cmd.name.trim().isEmpty) return CustomCommandResult.nameRequired;
    return null;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_commands.map((c) => c.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }
}
