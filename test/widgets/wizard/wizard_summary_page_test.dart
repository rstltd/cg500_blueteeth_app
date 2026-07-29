import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import 'package:cg500_blueteeth_app/view_models/quick_setup_view_model.dart';
import 'package:cg500_blueteeth_app/widgets/wizard/wizard_summary_page.dart';

void main() {
  const changed = SetupCommand(
    label: '設定 APN',
    commandString: r'$APN,internet.iot',
    oldValue: 'internet',
    newValue: 'internet.iot',
  );

  Widget wrap({required bool isConnected, required bool hasAnyChange}) {
    return MaterialApp(
      home: Scaffold(
        body: WizardSummaryPage(
          commands: hasAnyChange ? const [changed] : const [],
          hasAnyChange: hasAnyChange,
          isConnected: isConnected,
          onConfirm: () {},
          onBack: () {},
        ),
      ),
    );
  }

  group('WizardSummaryPage connection gating', () {
    // Regression cover for F-004. The wizard is full-screen, so an operator
    // could fill in all four steps after the device dropped and still be
    // invited to press 確認執行.
    testWidgets('confirm is disabled when disconnected', (tester) async {
      await tester.pumpWidget(wrap(isConnected: false, hasAnyChange: true));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text(AppStrings.pleaseConnectBleDeviceFirst), findsOneWidget);
    });

    testWidgets('confirm is enabled when connected', (tester) async {
      await tester.pumpWidget(wrap(isConnected: true, hasAnyChange: true));
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(find.text(AppStrings.pleaseConnectBleDeviceFirst), findsNothing);
    });

    testWidgets('no confirm button and no warning when nothing changed',
        (tester) async {
      await tester.pumpWidget(wrap(isConnected: false, hasAnyChange: false));
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsNothing);
      // The warning is about being unable to send changes; with nothing to
      // send it would only add noise.
      expect(find.text(AppStrings.pleaseConnectBleDeviceFirst), findsNothing);
    });

    testWidgets('back stays available while disconnected', (tester) async {
      await tester.pumpWidget(wrap(isConnected: false, hasAnyChange: true));
      await tester.pumpAndSettle();

      final back = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(back.onPressed, isNotNull);
    });
  });
}
