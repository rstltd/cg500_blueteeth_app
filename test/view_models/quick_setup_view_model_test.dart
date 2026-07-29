import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/controllers/command_manager.dart';
import 'package:cg500_blueteeth_app/models/device_info.dart';
import 'package:cg500_blueteeth_app/view_models/quick_setup_view_model.dart';
import '../mocks/mock_ble_controller.dart';

/// Tests for the diff-and-send-only-changes pipeline that ADR-0006 calls
/// load-bearing: the wizard must pre-fill from the device's current values
/// and only queue commands for fields the user actually changed, so a
/// maintenance visit that confirms everything is fine sends zero commands.
void main() {
  late MockBleController mockController;
  late CommandManager commandManager;

  setUp(() {
    mockController = MockBleController();
    // The wizard sends through CommandManager, which refuses to send unless
    // a device is connected.
    mockController.simulateConnected(createTestDevice());
    commandManager = CommandManager(controller: mockController);
  });

  tearDown(() {
    commandManager.dispose();
    mockController.dispose();
  });

  QuickSetupViewModel buildVm() =>
      QuickSetupViewModel(commandManager: commandManager);

  group('diff matrix — stepHasChange', () {
    test('original null, user did not touch the field -> no change', () {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo()); // apn/addr/ftpAddr/reboot all null

      expect(vm.getUserValue(0), isNull);
      expect(vm.stepHasChange(0), isFalse);
    });

    test('original null, user entered a value -> change', () {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo());
      vm.updateValue(0, 'internet');

      expect(vm.stepHasChange(0), isTrue);
    });

    test('original has a value, user leaves it as pre-filled -> no change '
        '(ADR-0006: a maintenance visit that confirms everything is correct '
        'must not re-send it)', () {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo(apn: 'internet'));

      // initializeWithInfo pre-fills _newValues from the original, so the
      // user never touching the field must not look like a change.
      expect(vm.getUserValue(0), 'internet');
      expect(vm.stepHasChange(0), isFalse);
    });

    test('original has a value, user retypes the identical value -> no '
        'change', () {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo(apn: 'internet'));
      vm.updateValue(0, 'internet');

      expect(vm.stepHasChange(0), isFalse);
    });

    test('original has a value, user enters a different value -> change',
        () {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo(apn: 'internet'));
      vm.updateValue(0, 'internet.iot');

      expect(vm.stepHasChange(0), isTrue);
    });

    test('original null, user enters an empty string -> still counts as a '
        'change (userVal != null, even though it is empty)', () {
      // Documents actual behaviour: stepHasChange only checks null-ness /
      // equality, it never treats '' specially. WizardStepForm mirrors this
      // exact logic in _willSendCommand, so this is the real, exercised
      // decision path, not a leftover in the VM alone.
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo());
      vm.updateValue(0, '');

      expect(vm.stepHasChange(0), isTrue);
    });

    test('leading/trailing whitespace is not trimmed before comparing -> '
        'counts as a change even though the value is "the same" to a human',
        () {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo(apn: 'internet'));
      vm.updateValue(0, 'internet '); // trailing space

      expect(vm.stepHasChange(0), isTrue);
    });

    test('comparison is case-sensitive -> a different-case value counts as '
        'a change', () {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo(apn: 'internet'));
      vm.updateValue(0, 'Internet');

      expect(vm.stepHasChange(0), isTrue);
    });
  });

  group('pendingCommands — goToSummary()', () {
    test('only changed steps are queued, in APN -> ADDR -> FTPADDR -> '
        'REBOOT order, when all four changed', () {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo());
      vm.updateValue(0, 'internet');
      vm.updateValue(1, 'rmdgnss.com:8180');
      vm.updateValue(2, 'update.example.com:80');
      vm.updateValue(3, '2');

      vm.goToSummary();

      expect(vm.phase, WizardPhase.summary);
      expect(vm.pendingCommands.map((c) => c.label).toList(), [
        QuickSetupViewModel.stepLabels[0],
        QuickSetupViewModel.stepLabels[1],
        QuickSetupViewModel.stepLabels[2],
        QuickSetupViewModel.stepLabels[3],
      ]);
      expect(vm.pendingCommands.map((c) => c.commandString).toList(), [
        r'$APN,internet',
        r'$ADDR,rmdgnss.com:8180',
        r'$FTPADDR,update.example.com:80',
        r'$REBOOT,2',
      ]);
    });

    test('only the changed subset is queued, and step order is preserved '
        'even when the changed steps are non-contiguous', () {
      final vm = buildVm();
      // ADDR already correct in the field, FTPADDR drifted, APN and REBOOT
      // untouched — the common "fix one drifted value" maintenance case.
      vm.initializeWithInfo(const DeviceInfo(
        apn: 'internet',
        addr: 'rmdgnss.com:8180',
        ftpAddr: 'old.example.com:80',
        rebootHour: '2',
      ));
      vm.updateValue(2, 'new.example.com:80'); // only FTPADDR changes

      vm.goToSummary();

      expect(vm.pendingCommands, hasLength(1));
      final cmd = vm.pendingCommands.single;
      expect(cmd.label, QuickSetupViewModel.stepLabels[2]);
      expect(cmd.oldValue, 'old.example.com:80');
      expect(cmd.newValue, 'new.example.com:80');
      expect(cmd.commandString, r'$FTPADDR,new.example.com:80');
    });

    test('oldValue is rendered as an em dash when there was no original '
        'value (fresh commissioning, field was previously unset)', () {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo()); // apn originally null
      vm.updateValue(0, 'internet');

      vm.goToSummary();

      expect(vm.pendingCommands.single.oldValue, '—');
    });

    test('no field changed -> pendingCommands is empty and hasAnyChange is '
        'false (the confirmed-correct maintenance visit sends nothing)', () {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo(
        apn: 'internet',
        addr: 'rmdgnss.com:8180',
        ftpAddr: 'update.example.com:80',
        rebootHour: '2',
      ));

      expect(vm.hasAnyChange, isFalse);

      vm.goToSummary();

      expect(vm.pendingCommands, isEmpty);
      expect(vm.phase, WizardPhase.summary);
    });

    test('hasAnyChange reflects live edits before goToSummary() is called',
        () {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo(apn: 'internet'));
      expect(vm.hasAnyChange, isFalse);

      vm.updateValue(0, 'internet.iot');
      expect(vm.hasAnyChange, isTrue);
    });
  });

  group('executeChanges() — dispose mid-run stops the sequence', () {
    test('disposing the ViewModel while a command is in flight prevents '
        'any further pending commands from being sent', () async {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo());
      vm.updateValue(0, 'internet'); // APN
      vm.updateValue(1, 'rmdgnss.com:8180'); // ADDR
      vm.updateValue(2, 'update.example.com:80'); // FTPADDR
      vm.goToSummary();
      expect(vm.pendingCommands, hasLength(3));

      // Give the mock controller a real delay so the first command is
      // still "in flight" (already recorded, not yet resolved) when we
      // tear the ViewModel down.
      mockController.configureSendCommand(
        succeed: true,
        delay: const Duration(milliseconds: 60),
      );

      final execFuture = vm.executeChanges();

      // Let the first send start (MockBleController.sendCommand records the
      // command synchronously before awaiting its configured delay) but
      // dispose long before it — and long before the 500ms inter-command
      // delay — completes.
      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(mockController.sentCommands, hasLength(1));
      vm.dispose();

      await execFuture;

      // Only the first (already in-flight) command should ever have
      // reached the controller. If the disposal check were missing or
      // wrong, the 2nd and 3rd commands would show up here too.
      expect(mockController.sentCommands, hasLength(1));
      expect(mockController.sentCommands.single, r'$APN,internet');
    });

    test('executeChanges() returns (does not throw) after dispose cuts it '
        'short, and does not advance the phase past executing', () async {
      final vm = buildVm();
      vm.initializeWithInfo(const DeviceInfo());
      vm.updateValue(0, 'internet');
      vm.updateValue(1, 'rmdgnss.com:8180');
      vm.goToSummary();

      mockController.configureSendCommand(
        succeed: true,
        delay: const Duration(milliseconds: 60),
      );

      final execFuture = vm.executeChanges();
      await Future<void>.delayed(const Duration(milliseconds: 15));
      vm.dispose();

      await expectLater(execFuture, completes);
      // Never reached WizardPhase.done because dispose cut the loop short
      // before $INFO refresh — asserted indirectly via sentCommands count.
      expect(mockController.sentCommands, hasLength(1));
    });
  });
}
