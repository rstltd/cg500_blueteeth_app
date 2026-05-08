import 'package:cg500_blueteeth_app/controllers/command_manager.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/device_info.dart';
import 'package:cg500_blueteeth_app/view_models/quick_setup_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_ble_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBleController controller;
  late CommandManager commandManager;
  late QuickSetupViewModel vm;

  setUp(() async {
    controller = MockBleController();
    controller.simulateConnected(const BleDeviceModel(
      id: 'A01LT00042',
      name: 'A01LT00042',
      displayName: 'A01LT00042',
    ));
    commandManager = CommandManager(controller: controller);
    vm = QuickSetupViewModel(commandManager: commandManager);
    await vm.initialize();
  });

  tearDown(() {
    vm.dispose();
    commandManager.dispose();
    controller.dispose();
  });

  /// Seed the VM with a baseline device info, optionally pre-changing
  /// some steps so that `pendingCommands` is non-empty.
  void initWithSomeChanges() {
    vm.initializeWithInfo(const DeviceInfo(
      apn: 'oldapn',
      addr: 'oldhost:1111',
      ftpAddr: 'oldftp:80',
      rebootHour: '2',
    ));
    // Change APN only — one diff.
    vm.updateValue(0, 'newapn');
    vm.goToSummary();
  }

  void initWithoutChanges() {
    vm.initializeWithInfo(const DeviceInfo(
      apn: 'oldapn',
      addr: 'oldhost:1111',
      ftpAddr: 'oldftp:80',
      rebootHour: '2',
    ));
    vm.goToSummary();
  }

  group('willReboot getter (ADR-0007 conditional dispatch)', () {
    test('false when no diffs are staged', () {
      initWithoutChanges();
      expect(vm.willReboot, isFalse);
      expect(vm.hasAnyChange, isFalse);
    });

    test('true when at least one diff is staged', () {
      initWithSomeChanges();
      expect(vm.willReboot, isTrue);
      expect(vm.hasAnyChange, isTrue);
    });
  });

  group('executeChanges — review-only path (zero diffs)', () {
    test('sends nothing — no \$INFO, no \$STARTX', () async {
      initWithoutChanges();
      await vm.executeChanges();

      expect(controller.sentCommands, isEmpty,
          reason: 'ADR-0006: zero-diff run must not touch the device.');
      expect(vm.phase, WizardPhase.done);
      expect(vm.failureMessage, isNull);
    });
  });

  group('executeChanges — full chain (one+ diffs)', () {
    test('dispatches [diffed commands] → \$INFO → \$STARTX in order',
        () async {
      initWithSomeChanges();
      await vm.executeChanges();

      expect(vm.phase, WizardPhase.done);
      expect(vm.failureMessage, isNull);
      expect(controller.sentCommands, [
        r'$APN,newapn',
        r'$INFO',
        r'$STARTX',
      ]);
    });

    test('multi-change run preserves the diff order', () async {
      vm.initializeWithInfo(const DeviceInfo(
        apn: 'oldapn',
        addr: 'oldhost:1111',
        ftpAddr: 'oldftp:80',
        rebootHour: '2',
      ));
      vm.updateValue(0, 'newapn');
      vm.updateValue(1, 'newhost:2222');
      vm.updateValue(2, 'newftp:81');
      vm.goToSummary();

      await vm.executeChanges();

      expect(vm.phase, WizardPhase.done);
      expect(controller.sentCommands, [
        r'$APN,newapn',
        r'$ADDR,newhost:2222',
        r'$FTPADDR,newftp:81',
        r'$INFO',
        r'$STARTX',
      ]);
    });
  });

  group('executeChanges — failure paths', () {
    test('diffed-command failure ends in failed phase with command label',
        () async {
      initWithSomeChanges();
      controller.configureSendCommand(succeed: false);

      await vm.executeChanges();

      expect(vm.phase, WizardPhase.failed);
      expect(vm.failureMessage, '設定 APN');
      expect(controller.sentCommands, [r'$APN,newapn']);
    });

    test(
        '\$STARTX failure ends in failed phase with the dedicated reboot '
        'message (ADR-0007)', () async {
      initWithSomeChanges();
      // Let the diffed command + $INFO succeed, but make $STARTX fail.
      // Configure on-the-fly: succeed for first 2 calls, fail thereafter.
      // Simpler: count calls and toggle.
      var callCount = 0;
      controller.configureSendCommand(succeed: true);
      // We need a fail-on-third-call hook. The mock doesn't support that
      // directly — instead, reconfigure after $INFO is sent. Detect by
      // listening to sentCommands and toggling at the right moment.
      // Practical workaround: use a custom interceptor. The mock records
      // every call; we toggle configureSendCommand(succeed: false) once
      // we've observed the $INFO call.
      // For this test, we simulate that pattern by polling sentCommands.

      // Kick off the execution.
      final future = vm.executeChanges();

      // Wait until $INFO has been queued (sentCommands grows past the
      // diffed commands), then flip the success flag for the next call
      // ($STARTX). Use a short polling loop.
      while (controller.sentCommands.length < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (++callCount > 200) {
          fail('Timed out waiting for \$INFO to be queued');
        }
      }
      controller.configureSendCommand(succeed: false);

      await future;

      expect(vm.phase, WizardPhase.failed);
      expect(vm.failureMessage, AppStrings.wizardRebootFailedMessage);
      // The diffed command, $INFO, and the failed $STARTX should all
      // appear in sentCommands (the mock records every attempt regardless
      // of success).
      expect(controller.sentCommands, [
        r'$APN,newapn',
        r'$INFO',
        r'$STARTX',
      ]);
    });
  });

  group('stepLabels / stepCommands invariants (ADR-0007)', () {
    test('form remains 4 steps; \$STARTX is not a form step', () {
      expect(QuickSetupViewModel.totalFormSteps, 4);
      expect(QuickSetupViewModel.stepLabels.length, 4);
      expect(QuickSetupViewModel.stepCommands.length, 4);
      expect(QuickSetupViewModel.stepCommands, isNot(contains(r'$STARTX')));
    });
  });
}
