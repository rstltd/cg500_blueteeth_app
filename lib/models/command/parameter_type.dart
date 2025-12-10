/// Parameter type for command parameters.
///
/// Determines the input widget type and validation logic.
enum ParameterType {
  /// Plain text input
  /// Examples: Device ID for $MAC, APN name for $APN
  text,

  /// IP address and port combination input
  /// Format: `IP:Port`
  /// Examples: $FTPADDR
  ipPort,

  /// Host (IP or domain) and port combination input
  /// Format: `Host:Port` where Host can be IP (192.168.1.1) or domain (example.com)
  /// Note: Domain should NOT include http/https prefix (TCP connection, not HTTP)
  /// Examples: $ADDR
  hostPort,

  /// Numeric input with optional range validation
  /// Examples: General numeric values
  number,

  /// Hour picker (0-23) with time display
  /// Examples: $REBOOT
  hourPicker,

  /// Multiple checkbox selection with bitwise value calculation
  /// Examples: $ALARM (SD=1, GPS=2, TCP=4, ADC=8)
  bitFlags,

  /// Dropdown selection from predefined options
  /// Examples: $APN (internet, internet.iot)
  dropdown,
}

/// Extension methods for [ParameterType].
extension ParameterTypeExtension on ParameterType {
  /// Returns the display name for the parameter type.
  String get displayName {
    switch (this) {
      case ParameterType.text:
        return '文字';
      case ParameterType.ipPort:
        return 'IP:Port';
      case ParameterType.hostPort:
        return '主機:Port';
      case ParameterType.number:
        return '數字';
      case ParameterType.hourPicker:
        return '小時';
      case ParameterType.bitFlags:
        return '多選';
      case ParameterType.dropdown:
        return '選單';
    }
  }

  /// Returns the keyboard type for this parameter.
  String get keyboardType {
    switch (this) {
      case ParameterType.text:
        return 'text';
      case ParameterType.ipPort:
        return 'number';
      case ParameterType.hostPort:
        return 'text'; // Can be domain or IP
      case ParameterType.number:
        return 'number';
      case ParameterType.hourPicker:
        return 'none'; // Uses picker
      case ParameterType.bitFlags:
        return 'none'; // Uses checkboxes
      case ParameterType.dropdown:
        return 'none'; // Uses dropdown
    }
  }

  /// Returns whether this parameter type uses a custom input widget.
  bool get usesCustomWidget {
    switch (this) {
      case ParameterType.text:
        return false;
      case ParameterType.ipPort:
        return true;
      case ParameterType.hostPort:
        return true;
      case ParameterType.number:
        return false;
      case ParameterType.hourPicker:
        return true;
      case ParameterType.bitFlags:
        return true;
      case ParameterType.dropdown:
        return true;
    }
  }

  /// Returns the hint text for the parameter type.
  String get defaultHint {
    switch (this) {
      case ParameterType.text:
        return '請輸入文字';
      case ParameterType.ipPort:
        return '例如: 192.168.1.1:8080';
      case ParameterType.hostPort:
        return '例如: rmdgnss.com:8080 或 192.168.1.1:8080';
      case ParameterType.number:
        return '請輸入數字';
      case ParameterType.hourPicker:
        return '選擇小時 (0-23)';
      case ParameterType.bitFlags:
        return '選擇選項';
      case ParameterType.dropdown:
        return '請選擇';
    }
  }
}
