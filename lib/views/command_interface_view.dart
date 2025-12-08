import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../core/view_model/view_model.dart';
import '../services/notification_service.dart';
import '../core/mixins/notification_listener_mixin.dart';
import '../view_models/command_interface_view_model.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/message_bubble_widget.dart';
import '../widgets/connection_status_widget.dart';
import '../widgets/device_status_panel_widget.dart';
import '../widgets/command_input_panel_widget.dart';
import '../widgets/command_history_panel_widget.dart';
import '../widgets/connection_stats_panel_widget.dart';

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
            tooltip: 'Clear Messages',
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
        title: const Text('Command Interface'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Initializing command interface...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScaffold(BuildContext context, String error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Interface'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.initialize(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPanel() {
    return DeviceStatusPanelWidget(controller: viewModel.controller);
  }

  Widget _buildResponseArea() {
    // Convert MessageData to Map for existing widget compatibility
    final messageMaps =
        viewModel.messages.map((m) => m.toMap()).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Communication',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: viewModel.clearMessages,
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear Messages',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: MessageListWidget(
                messages: messageMaps,
                scrollController: viewModel.scrollController,
                autoScroll: true,
              ),
            ),
          ),
        ],
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
        Expanded(child: _buildResponseArea()),
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
    return ResponsiveContainer(
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: Column(
              children: [
                _buildStatusPanel(),
                const SizedBox(height: 16),
                _buildCommandHistoryPanel(),
              ],
            ),
          ),
          Container(
            width: 1,
            color: AppColors.borderColor(context),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: Column(
              children: [
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
                const SizedBox(height: 16),
                _buildCommandHistoryPanel(),
                const SizedBox(height: 16),
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
            margin: const EdgeInsets.symmetric(horizontal: 24),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  child: Row(
                    children: [
                      ResponsiveText(
                        'Device Communication',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary(context),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: viewModel.clearMessages,
                        icon: const Icon(Icons.clear_all),
                        tooltip: 'Clear Messages',
                      ),
                    ],
                  ),
                ),
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
