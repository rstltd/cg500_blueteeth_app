/// User-defined BLE command stored in SharedPreferences.
///
/// v1 only supports plain text commands — values are baked into the
/// [command] string. For example, a user who needs to set MAC address
/// CN001 would save `$MAC,CN001` directly rather than parameterize it.
/// Parameterized custom commands are deferred to a future v2.
class CustomCommand {
  const CustomCommand({
    required this.command,
    required this.name,
    this.description = '',
  });

  /// The literal command string sent to the device (e.g. `$MAC,CN001`).
  final String command;

  /// Display name shown in lists and menus (e.g. "Set MAC CN001").
  final String name;

  /// Optional description / notes.
  final String description;

  /// Normalized key for duplicate detection: trimmed and upper-cased.
  String get normalizedKey => command.trim().toUpperCase();

  CustomCommand copyWith({
    String? command,
    String? name,
    String? description,
  }) =>
      CustomCommand(
        command: command ?? this.command,
        name: name ?? this.name,
        description: description ?? this.description,
      );

  Map<String, dynamic> toJson() => {
        'command': command,
        'name': name,
        'description': description,
      };

  factory CustomCommand.fromJson(Map<String, dynamic> json) => CustomCommand(
        command: json['command'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomCommand &&
          runtimeType == other.runtimeType &&
          command == other.command &&
          name == other.name &&
          description == other.description;

  @override
  int get hashCode => Object.hash(command, name, description);

  @override
  String toString() =>
      'CustomCommand(command: $command, name: $name, description: $description)';
}
