import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../core/view_model/view_model.dart';
import '../design/design_system.dart';
import '../l10n/app_strings.dart';
import '../models/command/command.dart';
import '../services/notification_service.dart';
import '../core/mixins/notification_listener_mixin.dart';
import '../view_models/command_interface_view_model.dart';
import '../widgets/message/message_bubble_widget.dart';
import '../widgets/message/message_filter_widget.dart';
import '../widgets/ble/connection_status_widget.dart';
import '../widgets/ble/device_status_panel_widget.dart';
import '../widgets/message/command_input_panel_widget.dart';
import '../widgets/message/command_history_panel_widget.dart';
import '../widgets/ble/connection_stats_panel_widget.dart';
import '../widgets/command/command_widgets.dart';

/// Command Interface View using ViewModelProvider pattern.
///
/// Uses the ViewModelProvider pattern for better separation of concerns.
///
/// Key features:
/// - State management via CommandInterfaceViewModel
/// - Automatic subscription lifecycle management
/// - Clean, testable code structure
class CommandInterfaceView extends StatelessWidget {
  /// Creates a CommandInterfaceView using the service locator.
  const CommandInterfaceView({super.key}) : _controller = null;

  /// Creates a CommandInterfaceView with explicit dependencies for testing.
  const CommandInterfaceView.withDependencies({
    super.key,
    required BleControllerInterface controller,
  }) : _controller = controller;

  final BleControllerInterface? _controller;

  @override
  Widget build(BuildContext context) {
    return ViewModelProvider<CommandInterfaceViewModel>(
      create: () => CommandInterfaceViewModel(controller: _controller),
      builder: (context, viewModel, child) {
        return _CommandInterfaceContent(viewModel: viewModel);
      },
    );
  }
}

/// The main content widget that uses the ViewModel.
class _CommandInterfaceContent extends StatefulWidget {
  const _CommandInterfaceContent({required this.viewModel});

  final CommandInterfaceViewModel viewModel;

  @override
  State<_CommandInterfaceContent> createState() =>
      _CommandInterfaceContentState();
}

class _CommandInterfaceContentState extends State<_CommandInterfaceContent>
    with NotificationListenerMixin<_CommandInterfaceContent> {
  CommandInterfaceViewModel get viewModel => widget.viewModel;

  @override
  Stream<NotificationModel> get notificationStream =>
      viewModel.controller.notificationStream;

  @override
  void initState() {
    super.initState();
    initializeNotificationListener();
  }

  @override
  void dispose() {
    disposeNotificationListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (!viewModel.isInitialized) {
      return _buildLoadingScaffold(context);
    }

    // Show error state
    if (viewModel.hasError) {
      return _buildErrorScaffold(context, viewModel.errorMessage!);
    }

    // Show main content
    return Scaffold(
      appBar: ConnectionStatusAppBar(
        controller: viewModel.controller,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: viewModel.clearMessages,
            tooltip: AppStrings.clearMessages,
          ),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        tablet: _buildTabletLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildLoadingScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.commandInterface),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: DesignTokens.spacingML),
            const Text(AppStrings.initializingCommandInterface),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.commandInterface),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: DesignTokens.iconXL, color: Colors.red),
            SizedBox(height: DesignTokens.spacingM),
            Text(AppStrings.error(error)),
            SizedBox(height: DesignTokens.spacingM),
            ElevatedButton(
              onPressed: () => viewModel.initialize(),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPanel() {
    return DeviceStatusPanelWidget(controller: viewModel.controller);
  }

  Widget _buildQuickAccessBar({bool compact = false}) {
    final isConnected = viewModel.controller.connectedDevice != null;
    return QuickAccessBarWidget(
      repository: viewModel.commandRepository,
      onCommandSelected: _onQuickCommandSelected,
      onOpenCommandMenu: _onOpenCommandMenu,
      executingCommand: viewModel.executingCommand,
      isConnected: isConnected,
      compact: compact,
    );
  }

  Future<void> _onQuickCommandSelected(DeviceCommand command) async {
    final success = await viewModel.executeQuickCommand(command);
    _showCommandFeedback(success, command.command);
  }

  void _onOpenCommandMenu() async {
    final isConnected = viewModel.controller.connectedDevice != null;

    final selectedCommand = await CommandMenuSheet.show(
      context: context,
      repository: viewModel.commandRepository,
      isConnected: isConnected,
    );

    if (selectedCommand != null && mounted) {
      await _executeCommand(selectedCommand);
    }
  }

  Future<void> _executeCommand(DeviceCommand command) async {
    final isConnected = viewModel.controller.connectedDevice != null;

    if (command.hasParameters) {
      // Show parameter form for commands with parameters
      final commandString = await CommandFormSheet.show(
        context: context,
        command: command,
        storageService: viewModel.parameterStorageService,
        isConnected: isConnected,
      );

      if (commandString != null && mounted) {
        // Check if command requires confirmation (warning or dangerous level)
        if (command.dangerLevel.requiresConfirmation) {
          final confirmed = await DangerConfirmDialog.show(
            context: context,
            command: command,
            commandString: commandString,
          );
          if (!confirmed) return;
        }

        final success = await viewModel.sendCommand(commandString);
        _showCommandFeedback(success, commandString);
      }
    } else {
      // For commands without parameters, check if confirmation is required first
      if (command.dangerLevel.requiresConfirmation) {
        final commandString = command.buildCommandString({});
        final confirmed = await DangerConfirmDialog.show(
          context: context,
          command: command,
          commandString: commandString,
        );
        if (!confirmed) return;
      }

      // Execute command directly
      final success = await viewModel.executeQuickCommand(command);
      _showCommandFeedback(success, command.command);
    }
  }

  /// Show feedback SnackBar after command execution.
  void _showCommandFeedback(bool success, String command) {
    if (!mounted) return;

    if (success) {
      context.showCommandSuccess(command: command);
    } else {
      context.showCommandFailure(command: command);
    }
  }

  Widget _buildResponseArea({bool compact = false}) {
    // Convert filtered MessageData to Map for existing widget compatibility
    final messageMaps =
        viewModel.filteredMessages.map((m) => m.toMap()).toList();

    return Container(
      padding: compact ? DesignTokens.paddingS : DesignTokens.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            Row(
              children: [
                Text(
                  AppStrings.communicationLog,
                  style: AppTextStyles.titleSmall(context),
                ),
                const Spacer(),
                IconButton(
                  onPressed: viewModel.clearMessages,
                  icon: const Icon(Icons.clear_all),
                  tooltip: AppStrings.clearMessages,
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingS),
          ],
          // Message filter tabs
          MessageFilterWidget(
            selectedFilter: viewModel.currentFilter,
            onFilterChanged: viewModel.setFilter,
            messageCounts: viewModel.messageCounts,
            compact: compact,
          ),
          SizedBox(height: DesignTokens.spacingS),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardColor(context),
                borderRadius: DesignTokens.borderRadiusM,
                border: Border.all(color: AppColors.borderColor(context)),
              ),
              child: Stack(
                children: [
                  MessageListWidget(
                    messages: messageMaps,
                    scrollController: viewModel.scrollController,
                  ),
                  if (viewModel.isAutoScrollPaused &&
                      viewModel.unreadCount > 0)
                    Positioned(
                      bottom: DesignTokens.spacingS,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildNewMessageIndicator(context),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewMessageIndicator(BuildContext context) {
    return GestureDetector(
      onTap: viewModel.resumeAutoScroll,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSM,
          vertical: DesignTokens.spacingXS,
        ),
        decoration: BoxDecoration(
          color: AppColors.infoColor(context),
          borderRadius: DesignTokens.borderRadiusL,
          boxShadow: DesignTokens.cardShadow(context),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_downward,
                size: 14, color: Colors.white),
            SizedBox(width: DesignTokens.spacingXS),
            Text(
              AppStrings.newMessages(viewModel.unreadCount),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandInput() {
    return CommandInputPanelWidget(
      controller: viewModel.controller,
      commandManager: viewModel.commandManager,
      onSendCommand: viewModel.sendCommand,
      onNavigateHistory: viewModel.navigateHistory,
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildStatusPanel(),
        _buildQuickAccessBar(compact: true),
        Expanded(child: _buildResponseArea(compact: true)),
        _buildCommandInput(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return ResponsiveUtils.isLandscape(context)
        ? _buildTabletLandscapeLayout()
        : _buildTabletPortraitLayout();
  }

  Widget _buildTabletPortraitLayout() {
    return ResponsiveContainer(
      child: Column(
        children: [
          _buildStatusPanel(),
          _buildQuickAccessBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveUtils.getCardMaxWidth(context) * 2,
                ),
                child: _buildResponseArea(),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveUtils.getCardMaxWidth(context) * 2,
              ),
              child: _buildCommandInput(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLandscapeLayout() {
    final sidebarWidth = ResponsiveUtils.getTabletSidebarWidth(context);

    return ResponsiveContainer(
      child: Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: Column(
              children: [
                _buildStatusPanel(),
                SizedBox(height: ResponsiveUtils.getTabletItemGap(context)),
                _buildCommandHistoryPanel(),
                // Show connection stats on larger tablets
                if (ResponsiveUtils.isTabletLarge(context)) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  ConnectionStatsPanelWidget(
                    controller: viewModel.controller,
                    commandManager: viewModel.commandManager,
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: DesignTokens.dividerThickness,
            color: AppColors.borderColor(context),
            margin: DesignTokens.paddingHorizontalM,
          ),
          Expanded(
            child: Column(
              children: [
                _buildQuickAccessBar(),
                Expanded(child: _buildResponseArea()),
                _buildCommandInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return ResponsiveContainer(
      child: Row(
        children: [
          SizedBox(
            width: 350,
            child: Column(
              children: [
                _buildStatusPanel(),
                SizedBox(height: DesignTokens.spacingM),
                _buildCommandHistoryPanel(),
                SizedBox(height: DesignTokens.spacingM),
                ConnectionStatsPanelWidget(
                  controller: viewModel.controller,
                  commandManager: viewModel.commandManager,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            color: AppColors.borderColor(context),
            margin: DesignTokens.paddingHorizontalL,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  child: Row(
                    children: [
                      ResponsiveText(
                        AppStrings.deviceCommunication,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: viewModel.clearMessages,
                        icon: const Icon(Icons.clear_all),
                        tooltip: AppStrings.clearMessages,
                      ),
                    ],
                  ),
                ),
                _buildQuickAccessBar(),
                Expanded(child: _buildResponseArea()),
                _buildCommandInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandHistoryPanel() {
    return CommandHistoryPanelWidget(commandManager: viewModel.commandManager);
  }
}
