import 'package:flutter/material.dart';
import '../../core/interfaces/command_repository_interface.dart';
import '../../design/design_system.dart';
import '../../models/command/command.dart';
import 'command_category_tabs.dart';
import 'command_list_tile.dart';
import 'command_search_bar.dart';

/// A bottom sheet that displays the full command menu.
///
/// Provides search, category filtering, and command selection.
class CommandMenuSheet extends StatefulWidget {
  /// The command repository to use.
  final CommandRepositoryInterface repository;

  /// Callback when a command is selected.
  final ValueChanged<DeviceCommand> onCommandSelected;

  /// Whether the device is connected.
  final bool isConnected;

  /// Initial category to show.
  final CommandCategory? initialCategory;

  const CommandMenuSheet({
    super.key,
    required this.repository,
    required this.onCommandSelected,
    this.isConnected = false,
    this.initialCategory,
  });

  /// Shows the command menu as a modal bottom sheet.
  static Future<DeviceCommand?> show({
    required BuildContext context,
    required CommandRepositoryInterface repository,
    bool isConnected = false,
    CommandCategory? initialCategory,
  }) {
    return showModalBottomSheet<DeviceCommand>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommandMenuSheet(
        repository: repository,
        onCommandSelected: (command) => Navigator.of(context).pop(command),
        isConnected: isConnected,
        initialCategory: initialCategory,
      ),
    );
  }

  @override
  State<CommandMenuSheet> createState() => _CommandMenuSheetState();
}

class _CommandMenuSheetState extends State<CommandMenuSheet> {
  CommandCategory? _selectedCategory;
  String _searchQuery = '';
  late List<DeviceCommand> _allCommands;
  late Map<CommandCategory, int> _categoryCounts;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _allCommands = widget.repository.getAllCommands();
    _categoryCounts = _calculateCategoryCounts();
  }

  Map<CommandCategory, int> _calculateCategoryCounts() {
    final counts = <CommandCategory, int>{};
    for (final category in CommandCategory.values) {
      counts[category] = widget.repository.getCommandsByCategory(category).length;
    }
    return counts;
  }

  List<DeviceCommand> get _filteredCommands {
    List<DeviceCommand> commands;

    // Filter by category first
    if (_selectedCategory != null) {
      commands = widget.repository.getCommandsByCategory(_selectedCategory!);
    } else {
      commands = _allCommands;
    }

    // Then filter by search query
    if (_searchQuery.isNotEmpty) {
      commands = commands.where((cmd) {
        final query = _searchQuery.toLowerCase();
        return cmd.name.toLowerCase().contains(query) ||
            cmd.command.toLowerCase().contains(query) ||
            cmd.description.toLowerCase().contains(query);
      }).toList();
    }

    return commands;
  }

  void _onCategorySelected(CommandCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onCommandTap(DeviceCommand command) {
    widget.onCommandSelected(command);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filteredCommands = _filteredCommands;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          _buildDragHandle(colorScheme),

          // Header
          _buildHeader(context),

          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            child: CommandSearchBar(
              onChanged: _onSearchChanged,
              hintText: '搜尋指令名稱或代碼...',
              autofocus: false,
            ),
          ),

          // Category tabs
          CommandCategoryTabs(
            selectedCategory: _selectedCategory,
            onCategorySelected: _onCategorySelected,
            categoryCounts: _categoryCounts,
            totalCount: _allCommands.length,
            showCounts: true,
          ),

          SizedBox(height: DesignTokens.spacingS),

          // Divider
          Divider(
            height: 1,
            color: colorScheme.outlineVariant,
          ),

          // Command list
          Expanded(
            child: filteredCommands.isEmpty
                ? _buildEmptyState(context)
                : _buildCommandList(filteredCommands),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(top: DesignTokens.spacingSM),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        borderRadius: DesignTokens.borderRadiusFull,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.spacingM,
        DesignTokens.spacingM,
        DesignTokens.spacingS,
        DesignTokens.spacingS,
      ),
      child: Row(
        children: [
          Icon(
            Icons.terminal,
            size: DesignTokens.iconM,
            color: colorScheme.primary,
          ),
          SizedBox(width: DesignTokens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '指令選單',
                  style: TextStyle(
                    fontSize: DesignTokens.fontTitle,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.isConnected ? '選擇指令發送到設備' : '設備未連線',
                  style: TextStyle(
                    fontSize: DesignTokens.fontS,
                    color: widget.isConnected
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: '關閉',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: DesignTokens.paddingL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: DesignTokens.iconXL,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: DesignTokens.spacingM),
            Text(
              '找不到符合的指令',
              style: TextStyle(
                fontSize: DesignTokens.fontL,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: DesignTokens.spacingS),
            Text(
              _searchQuery.isNotEmpty
                  ? '嘗試使用其他關鍵字搜尋'
                  : '此分類下沒有指令',
              style: TextStyle(
                fontSize: DesignTokens.fontM,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandList(List<DeviceCommand> commands) {
    return ListView.separated(
      padding: EdgeInsets.only(
        left: DesignTokens.spacingS,
        right: DesignTokens.spacingS,
        top: DesignTokens.spacingS,
        bottom: DesignTokens.spacingL + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: commands.length,
      separatorBuilder: (context, index) => SizedBox(height: DesignTokens.spacingXS),
      itemBuilder: (context, index) {
        final command = commands[index];
        return CommandListTile(
          command: command,
          onTap: widget.isConnected ? () => _onCommandTap(command) : null,
          showCommandString: true,
          compact: false,
        );
      },
    );
  }
}

/// A compact command menu for use in dialogs or smaller spaces.
class CompactCommandMenu extends StatefulWidget {
  /// The command repository to use.
  final CommandRepositoryInterface repository;

  /// Callback when a command is selected.
  final ValueChanged<DeviceCommand> onCommandSelected;

  /// Whether the device is connected.
  final bool isConnected;

  /// Maximum height of the menu.
  final double maxHeight;

  const CompactCommandMenu({
    super.key,
    required this.repository,
    required this.onCommandSelected,
    this.isConnected = false,
    this.maxHeight = 400,
  });

  @override
  State<CompactCommandMenu> createState() => _CompactCommandMenuState();
}

class _CompactCommandMenuState extends State<CompactCommandMenu> {
  String _searchQuery = '';

  List<DeviceCommand> get _filteredCommands {
    if (_searchQuery.isEmpty) {
      return widget.repository.getAllCommands();
    }
    return widget.repository.searchCommands(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final commands = _filteredCommands;

    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: DesignTokens.borderRadiusM,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(DesignTokens.spacingS),
            child: CompactCommandSearchBar(
              onChanged: (query) => setState(() => _searchQuery = query),
              hintText: '搜尋指令...',
            ),
          ),

          // Command list
          Flexible(
            child: commands.isEmpty
                ? Padding(
                    padding: DesignTokens.paddingM,
                    child: Text(
                      '找不到符合的指令',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(
                      left: DesignTokens.spacingXS,
                      right: DesignTokens.spacingXS,
                      bottom: DesignTokens.spacingS,
                    ),
                    itemCount: commands.length,
                    itemBuilder: (context, index) {
                      final command = commands[index];
                      return CompactCommandListTile(
                        command: command,
                        onTap: widget.isConnected
                            ? () => widget.onCommandSelected(command)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
