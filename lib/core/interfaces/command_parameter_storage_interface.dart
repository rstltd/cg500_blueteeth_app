/// Interface for command parameter storage service.
///
/// This interface abstracts the storage of command parameters,
/// enabling testing with mock implementations.
abstract class CommandParameterStorageInterface {
  /// Whether the service has been initialized.
  bool get isInitialized;

  /// Initialize the service.
  Future<void> initialize();

  /// Save parameter values for a command.
  Future<void> saveParameters(String command, Map<String, String> parameters);

  /// Get saved parameter values for a command.
  Map<String, String>? getParameters(String command);

  /// Clear saved parameters for a specific command.
  Future<void> clearParameters(String command);

  /// Clear all saved parameters.
  Future<void> clearAllParameters();

  /// Add a command to the history.
  Future<void> addToHistory(String commandString);

  /// Get command history.
  List<String> getHistory();

  /// Clear command history.
  Future<void> clearHistory();

  /// Get a specific parameter value.
  String? getParameterValue(String command, String parameterId);

  /// Check if parameters exist for a command.
  bool hasParameters(String command);

  /// Get all commands that have saved parameters.
  List<String> getCommandsWithSavedParameters();

  /// Get statistics about stored data.
  Map<String, dynamic> getStorageStats();
}
