import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing and retrieving command parameter values.
///
/// This service provides persistent storage for command parameters,
/// allowing the app to remember the last used values for each command.
///
/// Usage:
/// ```dart
/// final service = CommandParameterStorageService();
/// await service.initialize();
///
/// // Save parameters
/// await service.saveParameters('$ADDR', {'ip': '192.168.1.1', 'port': '8080'});
///
/// // Load parameters
/// final params = service.getParameters('$ADDR');
/// ```
class CommandParameterStorageService {
  static const String _storageKeyPrefix = 'command_params_';
  static const String _historyKey = 'command_history';
  static const int _maxHistoryEntries = 50;

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initialize the service.
  /// Must be called before using any other methods.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  /// Ensure the service is initialized.
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
        'CommandParameterStorageService has not been initialized. '
        'Call initialize() first.',
      );
    }
  }

  /// Get the storage key for a command.
  String _getStorageKey(String command) {
    // Normalize command name (remove $ prefix for consistency)
    final normalizedCommand = command.startsWith('\$')
        ? command.substring(1).toUpperCase()
        : command.toUpperCase();
    return '$_storageKeyPrefix$normalizedCommand';
  }

  /// Save parameter values for a command.
  ///
  /// [command] - The command name (e.g., '$ADDR', 'ADDR')
  /// [parameters] - Map of parameter id to value
  Future<void> saveParameters(
    String command,
    Map<String, String> parameters,
  ) async {
    _ensureInitialized();

    final key = _getStorageKey(command);
    final jsonString = jsonEncode(parameters);
    await _prefs!.setString(key, jsonString);
  }

  /// Get saved parameter values for a command.
  ///
  /// Returns null if no parameters have been saved for this command.
  /// [command] - The command name (e.g., '$ADDR', 'ADDR')
  Map<String, String>? getParameters(String command) {
    _ensureInitialized();

    final key = _getStorageKey(command);
    final jsonString = _prefs!.getString(key);

    if (jsonString == null) return null;

    try {
      final Map<String, dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return null;
    }
  }

  /// Clear saved parameters for a specific command.
  Future<void> clearParameters(String command) async {
    _ensureInitialized();

    final key = _getStorageKey(command);
    await _prefs!.remove(key);
  }

  /// Clear all saved parameters.
  Future<void> clearAllParameters() async {
    _ensureInitialized();

    final keys = _prefs!.getKeys().where(
          (key) => key.startsWith(_storageKeyPrefix),
        );

    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  /// Add a command to the history.
  ///
  /// [commandString] - The full command string that was sent
  Future<void> addToHistory(String commandString) async {
    _ensureInitialized();

    final history = getHistory();

    // Remove duplicate if exists
    history.remove(commandString);

    // Add to beginning
    history.insert(0, commandString);

    // Limit history size
    while (history.length > _maxHistoryEntries) {
      history.removeLast();
    }

    await _prefs!.setStringList(_historyKey, history);
  }

  /// Get command history.
  ///
  /// Returns a list of previously sent command strings, most recent first.
  List<String> getHistory() {
    _ensureInitialized();
    return _prefs!.getStringList(_historyKey)?.toList() ?? [];
  }

  /// Clear command history.
  Future<void> clearHistory() async {
    _ensureInitialized();
    await _prefs!.remove(_historyKey);
  }

  /// Get a specific parameter value.
  ///
  /// [command] - The command name
  /// [parameterId] - The parameter id
  String? getParameterValue(String command, String parameterId) {
    final params = getParameters(command);
    return params?[parameterId];
  }

  /// Check if parameters exist for a command.
  bool hasParameters(String command) {
    _ensureInitialized();
    final key = _getStorageKey(command);
    return _prefs!.containsKey(key);
  }

  /// Get all commands that have saved parameters.
  List<String> getCommandsWithSavedParameters() {
    _ensureInitialized();

    return _prefs!
        .getKeys()
        .where((key) => key.startsWith(_storageKeyPrefix))
        .map((key) => key.replaceFirst(_storageKeyPrefix, '\$'))
        .toList();
  }

  /// Get statistics about stored data.
  Map<String, dynamic> getStorageStats() {
    _ensureInitialized();

    final commandCount = _prefs!
        .getKeys()
        .where((key) => key.startsWith(_storageKeyPrefix))
        .length;
    final historyCount = getHistory().length;

    return {
      'commandsWithParams': commandCount,
      'historyEntries': historyCount,
      'maxHistoryEntries': _maxHistoryEntries,
    };
  }

  /// Create a testing instance with a mock SharedPreferences.
  /// For testing purposes only.
  static CommandParameterStorageService forTesting(SharedPreferences prefs) {
    final service = CommandParameterStorageService();
    service._prefs = prefs;
    service._isInitialized = true;
    return service;
  }
}
