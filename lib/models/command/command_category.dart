/// Command category for organizing device commands.
///
/// Used to group commands by their purpose in the UI.
enum CommandCategory {
  /// Query commands - retrieve information from device
  /// Examples: $CMD, $INFO, $SHOWP
  query,

  /// Configuration commands - modify device settings
  /// Examples: $MAC, $APN, $ADDR, $ALARM, $FTPADDR
  config,

  /// Control commands - control device behavior
  /// Examples: $STARTX, $TCPX, $REBOOT
  control,

  /// Debug commands - for development and troubleshooting
  /// Examples: $DEBUG
  debug,

  /// User-defined custom commands persisted in SharedPreferences.
  /// Only visible in developer mode.
  custom,
}

/// Extension methods for [CommandCategory].
extension CommandCategoryExtension on CommandCategory {
  /// Returns the display name for the category.
  String get displayName {
    switch (this) {
      case CommandCategory.query:
        return '查詢';
      case CommandCategory.config:
        return '設定';
      case CommandCategory.control:
        return '控制';
      case CommandCategory.debug:
        return '除錯';
      case CommandCategory.custom:
        return '自訂';
    }
  }

  /// Returns the icon name for the category.
  String get iconName {
    switch (this) {
      case CommandCategory.query:
        return 'info_outline';
      case CommandCategory.config:
        return 'settings';
      case CommandCategory.control:
        return 'sync';
      case CommandCategory.debug:
        return 'bug_report';
      case CommandCategory.custom:
        return 'edit_note';
    }
  }

  /// Returns the description for the category.
  String get description {
    switch (this) {
      case CommandCategory.query:
        return '查詢設備資訊和狀態';
      case CommandCategory.config:
        return '修改設備設定';
      case CommandCategory.control:
        return '控制設備行為';
      case CommandCategory.debug:
        return '開發和除錯用途';
      case CommandCategory.custom:
        return '使用者自行新增的指令';
    }
  }

  /// Returns the sort order for displaying categories.
  int get sortOrder {
    switch (this) {
      case CommandCategory.query:
        return 0;
      case CommandCategory.config:
        return 1;
      case CommandCategory.control:
        return 2;
      case CommandCategory.debug:
        return 3;
      case CommandCategory.custom:
        return 4;
    }
  }
}
