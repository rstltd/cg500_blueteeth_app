import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
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

  /// Creates a Host:Port parameter (supports IP or domain).
  ///
  /// [defaultHost] can be an IP address (e.g., "192.168.1.1") or
  /// a domain name (e.g., "rmdgnss.com") without http/https prefix.
  factory CommandParameter.hostPort({
    required String id,
    required String label,
    String? defaultHost,
    String? defaultPort,
    bool required = true,
  }) {
    return CommandParameter(
      id: id,
      label: label,
      type: ParameterType.hostPort,
      hint: '例如: rmdgnss.com:8080 或 192.168.1.1:8080',
      defaultValue: defaultHost != null && defaultPort != null
          ? '$defaultHost:$defaultPort'
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

  /// Creates a dropdown parameter with predefined options.
  ///
  /// [dropdownOptions] is a list of selectable options.
  /// [defaultValue] should match one of the option values.
  factory CommandParameter.dropdown({
    required String id,
    required String label,
    required List<DropdownOption> dropdownOptions,
    String? defaultValue,
    bool required = true,
  }) {
    return CommandParameter(
      id: id,
      label: label,
      type: ParameterType.dropdown,
      defaultValue: defaultValue,
      required: required,
      options: {
        'dropdownOptions': dropdownOptions,
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

  /// Gets the dropdown options if this is a dropdown parameter.
  List<DropdownOption>? get dropdownOptions {
    if (type != ParameterType.dropdown || options == null) return null;
    final opts = options!['dropdownOptions'];
    if (opts is List<DropdownOption>) return opts;
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
      return AppStrings.requiredField(label);
    }

    if (value == null || value.isEmpty) {
      return null; // Optional and empty is valid
    }

    switch (type) {
      case ParameterType.text:
        return null; // Text accepts any value

      case ParameterType.ipPort:
        return _validateIpPort(value);

      case ParameterType.hostPort:
        return _validateHostPort(value);

      case ParameterType.number:
        return _validateNumber(value);

      case ParameterType.hourPicker:
        return _validateHour(value);

      case ParameterType.bitFlags:
        return _validateBitFlags(value);

      case ParameterType.dropdown:
        return _validateDropdown(value);
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

  String? _validateHostPort(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      return '格式錯誤，請使用 主機:Port 格式';
    }

    final host = parts[0];
    final port = parts[1];

    // Validate host (can be IP or domain)
    if (host.isEmpty) {
      return '主機位址不可為空';
    }

    // Check if it looks like an IP address
    if (_looksLikeIpAddress(host)) {
      final ipError = _validateIpAddress(host);
      if (ipError != null) {
        return ipError;
      }
    } else {
      // Validate as domain
      final domainError = _validateDomain(host);
      if (domainError != null) {
        return domainError;
      }
    }

    // Validate port
    final portNum = int.tryParse(port);
    if (portNum == null || portNum < 1 || portNum > 65535) {
      return 'Port 必須在 1-65535 之間';
    }

    return null;
  }

  bool _looksLikeIpAddress(String value) {
    // If it contains only digits and dots, it's likely an IP
    return RegExp(r'^[\d.]+$').hasMatch(value);
  }

  String? _validateIpAddress(String ip) {
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

    return null;
  }

  String? _validateDomain(String domain) {
    // Reject if contains http:// or https://
    if (domain.toLowerCase().startsWith('http://') ||
        domain.toLowerCase().startsWith('https://')) {
      return '請勿包含 http:// 或 https://，僅需輸入網域名稱';
    }

    // Domain validation regex:
    // - Labels separated by dots
    // - Each label: starts with letter/digit, can contain hyphens, ends with letter/digit
    // - Labels are 1-63 characters
    // - Total length <= 253 characters
    if (domain.length > 253) {
      return '網域名稱過長';
    }

    // Simple domain validation pattern
    // Allows: example.com, sub.example.com, rmdgnss.com, etc.
    final domainPattern = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    if (!domainPattern.hasMatch(domain)) {
      return '網域名稱格式錯誤';
    }

    // Must have at least one dot for a valid domain (e.g., example.com)
    if (!domain.contains('.')) {
      return '網域名稱必須包含至少一個點 (例如: rmdgnss.com)';
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

  String? _validateDropdown(String value) {
    final opts = dropdownOptions;
    if (opts == null || opts.isEmpty) {
      return null; // No options defined, accept any value
    }

    // Check if value matches one of the available options
    final validValues = opts.map((o) => o.value).toList();
    if (!validValues.contains(value)) {
      return '請從選單中選擇有效選項';
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

/// Represents a single option in a dropdown parameter.
class DropdownOption {
  /// The display label for this option.
  final String label;

  /// The actual value sent in the command.
  final String value;

  /// Optional description for this option.
  final String? description;

  const DropdownOption({
    required this.label,
    required this.value,
    this.description,
  });

  @override
  String toString() => 'DropdownOption(label: $label, value: $value)';
}
