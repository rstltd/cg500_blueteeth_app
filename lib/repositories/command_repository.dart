import 'package:flutter/material.dart';

import '../core/interfaces/command_repository_interface.dart';
import '../models/command/command_category.dart';
import '../models/command/command_parameter.dart';
import '../models/command/danger_level.dart';
import '../models/command/device_command.dart';

/// Repository for managing device command definitions.
///
/// Provides access to all available commands, search, and filtering capabilities.
/// Implements [CommandRepositoryInterface] for dependency injection support.
class CommandRepository implements CommandRepositoryInterface {
  /// Singleton instance
  static final CommandRepository _instance = CommandRepository._internal();

  factory CommandRepository() => _instance;

  CommandRepository._internal();

  /// All available device commands.
  late final List<DeviceCommand> _commands = _buildCommands();

  /// Get all commands.
  @override
  List<DeviceCommand> getAllCommands() {
    return List.unmodifiable(_commands);
  }

  /// Get commands filtered by category.
  @override
  List<DeviceCommand> getCommandsByCategory(CommandCategory category) {
    return _commands.where((cmd) => cmd.category == category).toList();
  }

  /// Get commands suitable for quick access (no params + safe).
  @override
  List<DeviceCommand> getQuickAccessCommands() {
    return _commands.where((cmd) => cmd.isQuickAccessible).toList();
  }

  /// Get a specific command by its command string.
  @override
  DeviceCommand? getCommand(String command) {
    final upperCommand = command.toUpperCase();
    try {
      return _commands.firstWhere(
        (cmd) => cmd.command.toUpperCase() == upperCommand,
      );
    } catch (_) {
      return null;
    }
  }

  /// Search commands by name, description, or command string.
  @override
  List<DeviceCommand> searchCommands(String query) {
    if (query.isEmpty) return _commands;

    final lowerQuery = query.toLowerCase();
    return _commands.where((cmd) {
      return cmd.command.toLowerCase().contains(lowerQuery) ||
          cmd.name.toLowerCase().contains(lowerQuery) ||
          cmd.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get all categories with their commands.
  @override
  Map<CommandCategory, List<DeviceCommand>> getGroupedCommands() {
    final grouped = <CommandCategory, List<DeviceCommand>>{};

    for (final category in CommandCategory.values) {
      final commands = getCommandsByCategory(category);
      if (commands.isNotEmpty) {
        grouped[category] = commands;
      }
    }

    return grouped;
  }

  /// Get commands that require confirmation.
  @override
  List<DeviceCommand> getDangerousCommands() {
    return _commands.where((cmd) => cmd.requiresConfirmation).toList();
  }

  /// Build all command definitions.
  List<DeviceCommand> _buildCommands() {
    return [
      // ==================== Query Commands ====================
      const DeviceCommand(
        command: '\$CMD',
        name: '顯示所有指令',
        description: '顯示設備支援的所有指令清單',
        category: CommandCategory.query,
        icon: Icons.list_alt,
        example: '\$CMD',
      ),
      const DeviceCommand(
        command: '\$INFO',
        name: '顯示設備資訊',
        description: '顯示設備的 MAC、電壓值、IP、Port、時間、韌體版本等資訊',
        category: CommandCategory.query,
        icon: Icons.info_outline,
        example: '\$INFO',
      ),
      const DeviceCommand(
        command: '\$SHOWP',
        name: '顯示內部參數',
        description: '顯示設備內部參數，供 RD 除錯使用',
        category: CommandCategory.debug,
        icon: Icons.code,
        example: '\$SHOWP',
      ),

      // ==================== Config Commands ====================
      DeviceCommand(
        command: '\$MAC',
        name: '設定設備代號',
        description: '設定此設備的識別代號',
        category: CommandCategory.config,
        icon: Icons.label_outline,
        parameters: [
          CommandParameter.text(
            id: 'deviceId',
            label: '設備代號',
            hint: '例如: CN001',
          ),
        ],
        example: '\$MAC,CN001',
      ),
      DeviceCommand(
        command: '\$APN',
        name: '設定 4G APN',
        description: '修改連線 4G 使用的 APN 名稱',
        category: CommandCategory.config,
        icon: Icons.signal_cellular_alt,
        parameters: [
          CommandParameter.dropdown(
            id: 'apnName',
            label: 'APN 名稱',
            dropdownOptions: const [
              DropdownOption(
                label: '一般 4G SIM 卡',
                value: 'internet',
                description: '適用於一般消費者 4G SIM 卡',
              ),
              DropdownOption(
                label: 'IoT 專用 SIM 卡',
                value: 'internet.iot',
                description: '適用於物聯網專用 SIM 卡',
              ),
            ],
            defaultValue: 'internet',
          ),
        ],
        example: '\$APN,internet',
      ),
      DeviceCommand(
        command: '\$ADDR',
        name: '設定 TCP 路徑',
        description: '設定 TCP 傳輸路徑的 IP/網域 和 Port',
        category: CommandCategory.config,
        icon: Icons.router,
        parameters: [
          CommandParameter.hostPort(
            id: 'tcpAddr',
            label: 'TCP 位址',
            defaultHost: 'rmdgnss.com',
            defaultPort: '8180',
          ),
        ],
        example: '\$ADDR,rmdgnss.com:8180',
      ),
      DeviceCommand(
        command: '\$ALARM',
        name: '設定顯示訊息',
        description: '設定要顯示的執行訊息類型 (SD、GPS、TCP、ADC)',
        category: CommandCategory.config,
        icon: Icons.notifications_active_outlined,
        parameters: [
          CommandParameter.bitFlags(
            id: 'alarmFlags',
            label: '訊息類型',
            flags: const [
              BitFlagOption(label: 'SD 卡', value: 1, description: 'SD 卡相關訊息'),
              BitFlagOption(label: 'GPS', value: 2, description: 'GPS 定位訊息'),
              BitFlagOption(label: 'TCP', value: 4, description: 'TCP 連線訊息'),
              BitFlagOption(label: 'ADC', value: 8, description: 'ADC 類比數位轉換訊息'),
            ],
            defaultValue: 15, // All flags enabled
          ),
        ],
        example: '\$ALARM,15',
      ),
      DeviceCommand(
        command: '\$FTPADDR',
        name: '設定韌體更新位址',
        description: '設定韌體更新的下載位址 (HTTP)',
        category: CommandCategory.config,
        icon: Icons.system_update_outlined,
        parameters: [
          CommandParameter.ipPort(
            id: 'ftpAddr',
            label: '更新位址',
          ),
        ],
        example: '\$FTPADDR,211.72.53.102:80',
      ),

      // ==================== Control Commands ====================
      DeviceCommand(
        command: '\$REBOOT',
        name: '設定定時重啟',
        description: '設定每天到指定整點時自動重啟設備',
        category: CommandCategory.control,
        icon: Icons.schedule,
        parameters: [
          CommandParameter.hourPicker(
            id: 'rebootHour',
            label: '重啟時間',
            defaultHour: 2,
          ),
        ],
        dangerLevel: DangerLevel.safe,
        example: '\$REBOOT,2',
      ),
      const DeviceCommand(
        command: '\$TCPX',
        name: '重啟 TCP',
        description: '重新啟動 TCP 連線流程（短暫離線約 5-10 秒，BLE 連線不受影響）',
        category: CommandCategory.control,
        icon: Icons.refresh,
        example: '\$TCPX',
      ),
      const DeviceCommand(
        command: '\$STARTX',
        name: '重啟 MCU',
        description: '重新啟動設備的微控制器',
        category: CommandCategory.control,
        icon: Icons.power_settings_new,
        dangerLevel: DangerLevel.dangerous,
        warningMessage: '此操作將重新啟動設備\n\n'
            '• 所有連線將中斷\n'
            '• 設備需要約 30 秒重新啟動\n'
            '• 未保存的設定可能丟失\n'
            '• 重啟期間請勿操作或斷電',
        example: '\$STARTX',
      ),

      // ==================== Debug Commands ====================
      const DeviceCommand(
        command: '\$DEBUG',
        name: '顯示 GPS 資料',
        description: '顯示 GPS 詳細資料',
        category: CommandCategory.debug,
        icon: Icons.gps_fixed,
        dangerLevel: DangerLevel.warning,
        warningMessage: '執行此指令後，設備需要手動重啟才能恢復正常傳輸',
        example: '\$DEBUG',
      ),
    ];
  }
}
