import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import 'package:cg500_blueteeth_app/models/device_info.dart';
import 'package:cg500_blueteeth_app/view_models/quick_setup_view_model.dart';
import 'package:cg500_blueteeth_app/widgets/wizard/wizard_execution_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpExecution(
    WidgetTester tester, {
    required WizardPhase phase,
    required List<SetupCommand> commands,
    required int executingIndex,
    required bool willReboot,
    DeviceInfo? updatedInfo,
    String? failureMessage,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WizardExecutionPage(
            phase: phase,
            commands: commands,
            executingIndex: executingIndex,
            willReboot: willReboot,
            updatedInfo: updatedInfo,
            failureMessage: failureMessage,
            onFinish: () {},
            onBack: () {},
          ),
        ),
      ),
    );
  }

  const oneChange = [
    SetupCommand(
      label: '設定 APN',
      commandString: r'$APN,newapn',
      oldValue: 'oldapn',
      newValue: 'newapn',
    ),
  ];

  group('WizardExecutionPage — \$STARTX step in command list', () {
    testWidgets('shows \$STARTX row when willReboot is true', (tester) async {
      await pumpExecution(
        tester,
        phase: WizardPhase.executing,
        commands: oneChange,
        executingIndex: 0,
        willReboot: true,
      );

      // $STARTX appears as a row label + command string in the progress list.
      expect(find.text(AppStrings.wizardRebootRowLabel), findsOneWidget);
      expect(find.text(r'$STARTX'), findsOneWidget);
    });

    testWidgets('omits \$STARTX row when willReboot is false', (tester) async {
      await pumpExecution(
        tester,
        phase: WizardPhase.executing,
        commands: oneChange,
        executingIndex: 0,
        willReboot: false,
      );

      expect(find.text(AppStrings.wizardRebootRowLabel), findsNothing);
      expect(find.text(r'$STARTX'), findsNothing);
    });
  });

  group('WizardExecutionPage — done-phase reboot banner', () {
    testWidgets('banner is shown when phase=done and willReboot=true',
        (tester) async {
      await pumpExecution(
        tester,
        phase: WizardPhase.done,
        commands: oneChange,
        executingIndex: oneChange.length + 1,
        willReboot: true,
        updatedInfo: const DeviceInfo(apn: 'newapn'),
      );

      expect(find.text(AppStrings.wizardDoneWithRebootBanner), findsOneWidget);
    });

    testWidgets('banner is hidden when phase=done and willReboot=false',
        (tester) async {
      await pumpExecution(
        tester,
        phase: WizardPhase.done,
        commands: const [],
        executingIndex: 0,
        willReboot: false,
        updatedInfo: const DeviceInfo(),
      );

      expect(find.text(AppStrings.wizardDoneWithRebootBanner), findsNothing);
    });
  });

  group('WizardExecutionPage — failed phase shows failure message', () {
    testWidgets(
      'reboot-failure message is rendered as the failedAt subtitle',
      (tester) async {
        await pumpExecution(
          tester,
          phase: WizardPhase.failed,
          commands: oneChange,
          executingIndex: oneChange.length + 1,
          willReboot: true,
          failureMessage: AppStrings.wizardRebootFailedMessage,
        );

        // The execution page wraps the failure message via failedAt(...).
        expect(
          find.text(
            AppStrings.failedAt(AppStrings.wizardRebootFailedMessage),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
