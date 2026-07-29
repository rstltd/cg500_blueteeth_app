import 'package:flutter/material.dart';
import '../controllers/ble_controller_interface.dart';
import '../controllers/command_manager.dart';
import '../core/service_locator.dart' show getIt;
import '../design/design_system.dart';
import '../l10n/app_strings.dart';
import '../models/ble_device.dart';
import '../models/command/command.dart';
import '../models/device_info.dart';
import '../repositories/command_repository.dart';
import '../view_models/quick_setup_view_model.dart';
import '../widgets/ble/connection_status_widget.dart';
import '../widgets/wizard/wizard_execution_page.dart';
import '../widgets/wizard/wizard_step_form.dart';
import '../widgets/wizard/wizard_summary_page.dart';

/// Full-screen wizard that guides field operators through the standard
/// device configuration flow: APN → ADDR → FTPADDR → REBOOT.
///
/// Each step pre-fills the current device value (parsed from the $INFO
/// response) and lets the user modify or skip. Only changed settings
/// are sent to the device.
class QuickSetupWizardView extends StatefulWidget {
  const QuickSetupWizardView({
    super.key,
    required this.controller,
    required this.commandManager,
    required this.initialInfo,
  });

  final BleControllerInterface controller;
  final CommandManager commandManager;

  /// Snapshot of the current device's parsed [DeviceInfo], taken from the
  /// shared [DeviceInfoTracker] when the wizard was opened.
  final DeviceInfo initialInfo;

  @override
  State<QuickSetupWizardView> createState() => _QuickSetupWizardViewState();
}

class _QuickSetupWizardViewState extends State<QuickSetupWizardView> {
  late final QuickSetupViewModel _viewModel;
  late final PageController _pageController;
  late final List<CommandParameter> _stepParameters;

  @override
  void initState() {
    super.initState();

    _viewModel = QuickSetupViewModel(
      commandManager: widget.commandManager,
    );
    _viewModel.initializeWithInfo(widget.initialInfo);
    _viewModel.addListener(_onViewModelChanged);

    _pageController = PageController();

    // Grab the CommandParameter definitions for each wizard step from
    // the canonical (un-filtered) CommandRepository so we get the full
    // dropdown options, hints, and validation logic.
    final repo = getIt<CommandRepository>();
    _stepParameters = [
      repo.getCommand(r'$APN')!.parameters.first,
      repo.getCommand(r'$ADDR')!.parameters.first,
      repo.getCommand(r'$FTPADDR')!.parameters.first,
      repo.getCommand(r'$REBOOT')!.parameters.first,
    ];
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    setState(() {});

    // Sync PageController with viewModel step (for form steps only).
    // Use a post-frame callback because the PageView may be re-mounted
    // (e.g. returning from summary → form) and won't have clients yet
    // within the same build frame.
    if (_viewModel.phase == WizardPhase.form) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        final targetPage = _viewModel.currentStep;
        if (_pageController.page?.round() != targetPage) {
          _pageController.jumpToPage(targetPage);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExecuting = _viewModel.phase == WizardPhase.executing;

    // Hiding the AppBar close button is not enough: the Android system back
    // gesture would pop the wizard while executeChanges() keeps writing the
    // remaining settings to the device, so the operator believes they
    // cancelled while the device is still being reconfigured.
    return PopScope(
      canPop: !isExecuting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.cannotLeaveWhileExecuting),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.quickSetup),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: isExecuting
              ? null // prevent back during execution
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
          actions: [
            // The wizard is full-screen, so it hides the connection status the
            // views underneath show. Without this an operator can fill in all
            // four steps without ever learning the device dropped.
            ConnectionStatusWidget(
              controller: widget.controller,
              compact: true,
              showDeviceInfo: false,
            ),
            SizedBox(width: DesignTokens.spacingM),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_viewModel.phase) {
      case WizardPhase.form:
        return _buildFormPages();
      case WizardPhase.summary:
        return StreamBuilder<BleDeviceModel?>(
          stream: widget.controller.connectedDeviceStream,
          builder: (context, snapshot) {
            final isConnected =
                (snapshot.data ?? widget.controller.connectedDevice) != null;
            return WizardSummaryPage(
              commands: _viewModel.pendingCommands,
              hasAnyChange: _viewModel.hasAnyChange,
              isConnected: isConnected,
              onConfirm: _viewModel.executeChanges,
              onBack: _viewModel.backToForm,
            );
          },
        );
      case WizardPhase.executing:
      case WizardPhase.done:
      case WizardPhase.failed:
        return WizardExecutionPage(
          phase: _viewModel.phase,
          commands: _viewModel.pendingCommands,
          executingIndex: _viewModel.executingIndex,
          failureMessage: _viewModel.failureMessage,
          updatedInfo: _viewModel.phase == WizardPhase.done
              ? _buildUpdatedInfo()
              : null,
          onFinish: () => Navigator.of(context).pop(),
          onBack: _viewModel.backToForm,
        );
    }
  }

  Widget _buildFormPages() {
    return Column(
      children: [
        // Step progress indicator
        _buildProgressIndicator(),
        // Form pages
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: QuickSetupViewModel.totalFormSteps,
            itemBuilder: (context, index) {
              return WizardStepForm(
                stepIndex: index,
                totalSteps: QuickSetupViewModel.totalFormSteps,
                title: QuickSetupViewModel.stepLabels[index],
                parameter: _stepParameters[index],
                currentDeviceValue: _viewModel.getOriginalValue(index),
                initialValue: _viewModel.getUserValue(index),
                onChanged: (value) => _viewModel.updateValue(index, value),
                isFirst: index == 0,
                isLast: index == QuickSetupViewModel.totalFormSteps - 1,
                onNext: () {
                  if (_viewModel.isLastFormStep) {
                    _viewModel.goToSummary();
                  } else {
                    _viewModel.nextStep();
                  }
                },
                onPrevious: _viewModel.previousStep,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingL,
        vertical: DesignTokens.spacingSM,
      ),
      child: Row(
        children: List.generate(QuickSetupViewModel.totalFormSteps, (index) {
          final isActive = index == _viewModel.currentStep;
          final isDone = index < _viewModel.currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color: isDone || isActive
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Build a DeviceInfo from the wizard's new values for the done screen.
  /// This is a best-effort reconstruction — the actual device state is in
  /// the $INFO response that was sent during execution. We use the pending
  /// commands to show what was set.
  DeviceInfo? _buildUpdatedInfo() {
    var info = _viewModel.originalInfo;
    for (final cmd in _viewModel.pendingCommands) {
      if (cmd.commandString.startsWith(r'$APN,')) {
        info = info.copyWith(apn: cmd.newValue);
      } else if (cmd.commandString.startsWith(r'$ADDR,')) {
        info = info.copyWith(addr: cmd.newValue);
      } else if (cmd.commandString.startsWith(r'$FTPADDR,')) {
        info = info.copyWith(ftpAddr: cmd.newValue);
      } else if (cmd.commandString.startsWith(r'$REBOOT,')) {
        info = info.copyWith(rebootHour: cmd.newValue);
      }
    }
    return info;
  }
}
