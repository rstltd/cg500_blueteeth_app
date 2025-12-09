import 'parameter_type.dart';

/// Represents a parameter definition for a device command.
///
/// Used to define the input requirements and validation rules
/// for command parameters.
class CommandParameter {
  /// Unique identifier for this parameter.
  final String id;

  /// Display label shown in the UI.
  final String label;

  /// The type of input widget to use.
  final ParameterType type;

  /// Placeholder/hint text for the input.
  final String? hint;

  /// Default value for the parameter.
  final String? defaultValue;

  /// Whether this parameter is required.
  final bool required;

  /// Additional options for specific parameter types.
  ///
  /// For [ParameterType.bitFlags]:
  /// - 'flags': List of BitFlagOption
  ///
  /// For [ParameterType.number]:
  /// - 'min': minimum value
  /// - 'max': maximum value
  ///
  /// For [ParameterType.hourPicker]:
  /// - 'minHour': minimum hour (default 0)
  /// - 'maxHour': maximum hour (default 23)
  final Map<String, dynamic>? options;

  /// Creates a command parameter definition.
  const CommandParameter({
    required this.id,
    required this.label,
    required this.type,
    this.hint,
    this.defaultValue,
    this.required = true,
    this.options,
  });

  /// Creates a text parameter.
  factory CommandParameter.text({
    required String id,
    required String label,
    String? hint,
    String? defaultValue,
    bool required = true,
  }) {
    return CommandParameter(
      id: id,
      label: label,
      type: ParameterType.text,
      hint: hint,
      defaultValue: defaultValue,
      required: required,
    );
  }

  /// Creates an IP:Port parameter.
  factory CommandParameter.ipPort({
    required String id,
    required String label,
    String? defaultIp,
    String? defaultPort,
    bool required = true,
  }) {
    return CommandParameter(
      id: id,
      label: label,
      type: ParameterType.ipPort,
      hint: '例如: 192.168.1.1:8080',
      defaultValue: defaultIp != null && defaultPort != null
          ? '$defaultIp:$defaultPort'
          : null,
      required: required,
    );
  }

  /// Creates a number parameter with optional range.
  factory CommandParameter.number({
    required String id,
    required String label,
    String? hint,
    int? min,
    int? max,
    String? defaultValue,
    bool required = true,
  }) {
    return CommandParameter(
      id: id,
      label: label,
      type: ParameterType.number,
      hint: hint,
      defaultValue: defaultValue,
      required: required,
      options: {
        if (min != null) 'min': min,
        if (max != null) 'max': max,
      },
    );
  }

  /// Creates an hour picker parameter.
  factory CommandParameter.hourPicker({
    required String id,
    required String label,
    int defaultHour = 0,
    bool required = true,
  }) {
    return CommandParameter(
      id: id,
      label: label,
      type: ParameterType.hourPicker,
      defaultValue: defaultHour.toString(),
      required: required,
      options: {
        'minHour': 0,
        'maxHour': 23,
      },
    );
  }

  /// Creates a bit flags parameter.
  factory CommandParameter.bitFlags({
    required String id,
    required String label,
    required List<BitFlagOption> flags,
    int? defaultValue,
    bool required = true,
  }) {
    return CommandParameter(
      id: id,
      label: label,
      type: ParameterType.bitFlags,
      defaultValue: defaultValue?.toString(),
      required: required,
      options: {
        'flags': flags,
      },
    );
  }

  /// Gets the bit flag options if this is a bitFlags parameter.
  List<BitFlagOption>? get bitFlagOptions {
    if (type != ParameterType.bitFlags || options == null) return null;
    final flags = options!['flags'];
    if (flags is List<BitFlagOption>) return flags;
    return null;
  }

  /// Gets the minimum value if this is a number parameter.
  int? get minValue {
    if (options == null) return null;
    return options!['min'] as int?;
  }

  /// Gets the maximum value if this is a number parameter.
  int? get maxValue {
    if (options == null) return null;
    return options!['max'] as int?;
  }

  /// Validates a value for this parameter.
  /// Returns null if valid, or an error message if invalid.
  String? validate(String? value) {
    if (required && (value == null || value.isEmpty)) {
      return '$label 為必填項目';
    }

    if (value == null || value.isEmpty) {
      return null; // Optional and empty is valid
    }

    switch (type) {
      case ParameterType.text:
        return null; // Text accepts any value

      case ParameterType.ipPort:
        return _validateIpPort(value);

      case ParameterType.number:
        return _validateNumber(value);

      case ParameterType.hourPicker:
        return _validateHour(value);

      case ParameterType.bitFlags:
        return _validateBitFlags(value);
    }
  }

  String? _validateIpPort(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return '格式錯誤，請使用 IP:Port 格式';
    }

    final ip = parts[0];
    final port = parts[1];

    // Validate IP
    final ipParts = ip.split('.');
    if (ipParts.length != 4) {
      return 'IP 位址格式錯誤';
    }

    for (final part in ipParts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return 'IP 位址格式錯誤';
      }
    }

    // Validate port
    final portNum = int.tryParse(port);
    if (portNum == null || portNum < 1 || portNum > 65535) {
      return 'Port 必須在 1-65535 之間';
    }

    return null;
  }

  String? _validateNumber(String value) {
    final num = int.tryParse(value);
    if (num == null) {
      return '請輸入有效數字';
    }

    final min = minValue;
    final max = maxValue;

    if (min != null && num < min) {
      return '數值不能小於 $min';
    }

    if (max != null && num > max) {
      return '數值不能大於 $max';
    }

    return null;
  }

  String? _validateHour(String value) {
    final hour = int.tryParse(value);
    if (hour == null || hour < 0 || hour > 23) {
      return '請選擇 0-23 之間的小時';
    }
    return null;
  }

  String? _validateBitFlags(String value) {
    final num = int.tryParse(value);
    if (num == null || num < 0) {
      return '無效的選項值';
    }

    final flags = bitFlagOptions;
    if (flags == null) return null;

    // Calculate max possible value
    int maxValue = 0;
    for (final flag in flags) {
      maxValue |= flag.value;
    }

    if (num > maxValue) {
      return '選項值超出範圍';
    }

    return null;
  }

  @override
  String toString() {
    return 'CommandParameter(id: $id, label: $label, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommandParameter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents a single option in a bit flags parameter.
class BitFlagOption {
  /// The display label for this option.
  final String label;

  /// The bit value for this option.
  final int value;

  /// Optional description for this option.
  final String? description;

  const BitFlagOption({
    required this.label,
    required this.value,
    this.description,
  });

  @override
  String toString() => 'BitFlagOption(label: $label, value: $value)';
}
