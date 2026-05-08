import '../controllers/command_manager.dart';
import '../core/view_model/view_model.dart';
import '../l10n/app_strings.dart';
import '../models/device_info.dart';
import '../utils/logger.dart';

/// A single pending command in the execution queue.
class SetupCommand {
  final String label;
  final String commandString;
  final String oldValue;
  final String newValue;

  const SetupCommand({
    required this.label,
    required this.commandString,
    required this.oldValue,
    required this.newValue,
  });
}

/// Wizard phases beyond the 4 form steps.
enum WizardPhase { form, summary, executing, done, failed }

/// ViewModel for the Quick Setup Wizard.
///
/// Manages a 4-step guided flow (APN → ADDR → FTPADDR → REBOOT),
/// tracks which values the user modified vs. skipped, and executes
/// only the changed commands in sequence.
class QuickSetupViewModel extends BaseViewModel {
  QuickSetupViewModel({
    required CommandManager commandManager,
  }) : _commandManager = commandManager;

  final CommandManager _commandManager;

  // ---- Step labels (used in the UI) ----
  static const List<String> stepLabels = [
    '設定 APN',
    '設定 TCP 位址',
    '設定韌體更新位址',
    '設定定時重啟',
  ];

  static const List<String> stepCommands = [
    r'$APN',
    r'$ADDR',
    r'$FTPADDR',
    r'$REBOOT',
  ];

  static const int totalFormSteps = 4;

  // ---- State ----

  int _currentStep = 0;
  WizardPhase _phase = WizardPhase.form;

  DeviceInfo _originalInfo = const DeviceInfo();
  final Map<int, String> _newValues = {};

  List<SetupCommand> _pendingCommands = [];
  int _executingIndex = -1;
  String? _failureMessage;

  DeviceInfo? _updatedInfo;

  // ---- Getters ----

  int get currentStep => _currentStep;
  WizardPhase get phase => _phase;
  DeviceInfo get originalInfo => _originalInfo;
  List<SetupCommand> get pendingCommands => _pendingCommands;
  int get executingIndex => _executingIndex;
  String? get failureMessage => _failureMessage;
  DeviceInfo? get updatedInfo => _updatedInfo;

  bool get isFirstStep => _currentStep == 0;
  bool get isLastFormStep => _currentStep == totalFormSteps - 1;

  /// Whether any step has a modification.
  bool get hasAnyChange => _pendingCommandsFromState().isNotEmpty;

  /// Whether [executeChanges] will dispatch a `$STARTX` after the diffed
  /// commands. Per ADR-0007 the reboot only fires when at least one
  /// configuration change is actually being sent — a review-only run
  /// (zero diffs) sends nothing, including no reboot.
  bool get willReboot => hasAnyChange;

  // ---- Initialization ----

  /// Seed the wizard with the current device info already accumulated by
  /// the shared [DeviceInfoTracker] in the command interface.
  void initializeWithInfo(DeviceInfo info) {
    _originalInfo = info;

    // Pre-fill _newValues with originals so the form inputs start there
    final originals = [
      _originalInfo.apn,
      _originalInfo.addr,
      _originalInfo.ftpAddr,
      _originalInfo.rebootHour,
    ];
    for (var i = 0; i < originals.length; i++) {
      if (originals[i] != null) {
        _newValues[i] = originals[i]!;
      }
    }
    safeNotifyListeners();
  }

  /// Original value for a given step index.
  String? getOriginalValue(int step) {
    switch (step) {
      case 0: return _originalInfo.apn;
      case 1: return _originalInfo.addr;
      case 2: return _originalInfo.ftpAddr;
      case 3: return _originalInfo.rebootHour;
      default: return null;
    }
  }

  /// Current user-entered value for a step (may equal the original).
  String? getUserValue(int step) => _newValues[step];

  /// Whether the user has changed the value relative to the original.
  bool stepHasChange(int step) {
    final original = getOriginalValue(step);
    final userVal = _newValues[step];
    if (original == null && userVal == null) return false;
    if (original == null && userVal != null) return true;
    return userVal != null && userVal != original;
  }

  // ---- Navigation ----

  void updateValue(int step, String value) {
    _newValues[step] = value;
  }

  void nextStep() {
    if (_phase == WizardPhase.form && _currentStep < totalFormSteps - 1) {
      _currentStep++;
      safeNotifyListeners();
    }
  }

  void previousStep() {
    if (_phase == WizardPhase.form && _currentStep > 0) {
      _currentStep--;
      safeNotifyListeners();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < totalFormSteps) {
      _currentStep = step;
      _phase = WizardPhase.form;
      safeNotifyListeners();
    }
  }

  void goToSummary() {
    _pendingCommands = _pendingCommandsFromState();
    _phase = WizardPhase.summary;
    safeNotifyListeners();
  }

  void backToForm() {
    _phase = WizardPhase.form;
    // Go to step 0 so the user can review from the beginning.
    _currentStep = 0;
    safeNotifyListeners();
  }

  // ---- Execution ----

  /// Execute all pending (changed) commands in order, then send `$INFO`,
  /// then `$STARTX` to apply the new configuration. ADR-0007 governs the
  /// dispatch shape: zero diffs send nothing at all (preserves the
  /// review-only path of ADR-0006); one or more diffs run the full chain
  /// `[diffed commands] → $INFO → $STARTX`.
  Future<void> executeChanges() async {
    _phase = WizardPhase.executing;
    _executingIndex = 0;
    _failureMessage = null;
    safeNotifyListeners();

    // Defensive guard: review-only runs short-circuit to done without
    // any device traffic. The summary page hides the Apply button when
    // there are zero diffs, so this branch is normally unreachable —
    // it exists to honour the ADR-0006 zero-commands invariant if a
    // future caller ever invokes this method on an empty queue.
    if (_pendingCommands.isEmpty) {
      _phase = WizardPhase.done;
      safeNotifyListeners();
      return;
    }

    // 1. Send each diffed config command in order.
    for (var i = 0; i < _pendingCommands.length; i++) {
      _executingIndex = i;
      safeNotifyListeners();

      final cmd = _pendingCommands[i];
      Logger.ui('Wizard sending: ${cmd.commandString}');

      final success = await _commandManager.sendPredefinedCommand(
        cmd.commandString,
      );

      if (!success) {
        _failureMessage = cmd.label;
        _phase = WizardPhase.failed;
        safeNotifyListeners();
        return;
      }

      // Small delay between commands so the device can process
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 2. Verification: $INFO returns the new on-device values pre-reboot.
    _executingIndex = _pendingCommands.length;
    safeNotifyListeners();
    await _fetchUpdatedInfo();

    // 3. $STARTX: trigger the full MCU reboot so APN / ADDR / FTPADDR
    //    actually take effect. Has to come after $INFO because BLE drops
    //    within ~30 s of $STARTX and may never come back during this
    //    session for accelerometers / inclinometers (CONTEXT.md
    //    operational asymmetry).
    _executingIndex = _pendingCommands.length + 1;
    safeNotifyListeners();
    Logger.ui(r'Wizard sending: $STARTX');
    final rebootSuccess =
        await _commandManager.sendPredefinedCommand(r'$STARTX');
    if (!rebootSuccess) {
      // Distinct failure wording so the engineer knows the prior config
      // writes succeeded — only the reboot dispatch failed (per ADR-0007).
      _failureMessage = AppStrings.wizardRebootFailedMessage;
      _phase = WizardPhase.failed;
      safeNotifyListeners();
      return;
    }

    _phase = WizardPhase.done;
    safeNotifyListeners();
  }

  Future<void> _fetchUpdatedInfo() async {
    await _commandManager.sendPredefinedCommand(r'$INFO');
    // Wait for the device to respond with all $INFO lines
    await Future.delayed(const Duration(seconds: 3));

    // Re-parse from the controller's response stream — the
    // CommandInterfaceViewModel has already accumulated the latest lines.
    // Since we don't have direct access to those messages here, we'll
    // read the updated DeviceInfo from the caller after pop.
  }

  // ---- Helpers ----

  List<SetupCommand> _pendingCommandsFromState() {
    final commands = <SetupCommand>[];

    for (var i = 0; i < totalFormSteps; i++) {
      if (!stepHasChange(i)) continue;

      final original = getOriginalValue(i) ?? '—';
      final newVal = _newValues[i]!;
      final commandString = '${stepCommands[i]},$newVal';

      commands.add(SetupCommand(
        label: stepLabels[i],
        commandString: commandString,
        oldValue: original,
        newValue: newVal,
      ));
    }

    return commands;
  }
}
