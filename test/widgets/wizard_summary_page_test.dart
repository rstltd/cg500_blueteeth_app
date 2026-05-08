import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import 'package:cg500_blueteeth_app/view_models/quick_setup_view_model.dart';
import 'package:cg500_blueteeth_app/widgets/wizard/wizard_summary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpSummary(
    WidgetTester tester, {
    required List<SetupCommand> commands,
    required bool hasAnyChange,
    required bool willReboot,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WizardSummaryPage(
            commands: commands,
            hasAnyChange: hasAnyChange,
            willReboot: willReboot,
            onConfirm: () {},
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

  group('WizardSummaryPage — reboot row visibility (ADR-0007)', () {
    testWidgets('shows reboot row when willReboot is true', (tester) async {
      await pumpSummary(
        tester,
        commands: oneChange,
        hasAnyChange: true,
        willReboot: true,
      );

      expect(find.text(AppStrings.wizardRebootRowLabel), findsOneWidget);
      expect(find.text(AppStrings.wizardRebootRowSubtitle), findsOneWidget);
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    });

    testWidgets('hides reboot row when willReboot is false', (tester) async {
      // hasAnyChange + willReboot are independent flags in the widget API;
      // when willReboot is false the row stays hidden even if there are
      // pending diffs (defensive — not a state the production VM produces).
      await pumpSummary(
        tester,
        commands: oneChange,
        hasAnyChange: true,
        willReboot: false,
      );

      expect(find.text(AppStrings.wizardRebootRowLabel), findsNothing);
      expect(find.byIcon(Icons.power_settings_new), findsNothing);
    });

    testWidgets('hides reboot row in zero-diff state', (tester) async {
      await pumpSummary(
        tester,
        commands: const [],
        hasAnyChange: false,
        willReboot: false,
      );

      expect(find.text(AppStrings.wizardRebootRowLabel), findsNothing);
      expect(find.text(AppStrings.noChangesDetected), findsOneWidget);
    });
  });

  group('WizardSummaryPage — Apply button copy switches (ADR-0007)', () {
    testWidgets('copy is "套用變更並重啟" when willReboot is true',
        (tester) async {
      await pumpSummary(
        tester,
        commands: oneChange,
        hasAnyChange: true,
        willReboot: true,
      );

      expect(find.text(AppStrings.confirmAndExecuteWithReboot), findsOneWidget);
      expect(find.text(AppStrings.confirmAndExecute), findsNothing);
    });

    testWidgets(
      'copy falls back to "套用變更" when willReboot is false but there '
      'are diffs (kept for symmetry per ADR-0007)',
      (tester) async {
        await pumpSummary(
          tester,
          commands: oneChange,
          hasAnyChange: true,
          willReboot: false,
        );

        expect(find.text(AppStrings.confirmAndExecute), findsOneWidget);
        expect(find.text(AppStrings.confirmAndExecuteWithReboot), findsNothing);
      },
    );

    testWidgets('Apply button is hidden in zero-diff state', (tester) async {
      await pumpSummary(
        tester,
        commands: const [],
        hasAnyChange: false,
        willReboot: false,
      );

      expect(find.text(AppStrings.confirmAndExecute), findsNothing);
      expect(find.text(AppStrings.confirmAndExecuteWithReboot), findsNothing);
      expect(find.text(AppStrings.backToModify), findsOneWidget);
    });
  });
}
