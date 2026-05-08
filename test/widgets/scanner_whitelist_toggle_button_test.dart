import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import 'package:cg500_blueteeth_app/widgets/ble/scanner_whitelist_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpButton(
    WidgetTester tester, {
    required bool enabled,
    required VoidCallback onPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              ScannerWhitelistToggleButton(
                enabled: enabled,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('ScannerWhitelistToggleButton (ADR-0008)', () {
    testWidgets('renders filter_alt icon when enabled', (tester) async {
      await pumpButton(tester, enabled: true, onPressed: () {});
      expect(find.byIcon(Icons.filter_alt), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt_off), findsNothing);
    });

    testWidgets('renders filter_alt_off icon when disabled', (tester) async {
      await pumpButton(tester, enabled: false, onPressed: () {});
      expect(find.byIcon(Icons.filter_alt_off), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt), findsNothing);
    });

    testWidgets('tap fires onPressed callback', (tester) async {
      var taps = 0;
      await pumpButton(tester, enabled: true, onPressed: () => taps++);

      await tester.tap(find.byIcon(Icons.filter_alt));
      expect(taps, 1);
    });

    testWidgets('tooltip uses the enabled-state copy when enabled',
        (tester) async {
      await pumpButton(tester, enabled: true, onPressed: () {});
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(
        iconButton.tooltip,
        AppStrings.scannerWhitelistFilterEnabledTooltip,
      );
    });

    testWidgets('tooltip uses the disabled-state copy when disabled',
        (tester) async {
      await pumpButton(tester, enabled: false, onPressed: () {});
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(
        iconButton.tooltip,
        AppStrings.scannerWhitelistFilterDisabledTooltip,
      );
    });

    testWidgets(
      'rebuilds with new icon when enabled flag changes between pumps',
      (tester) async {
        await pumpButton(tester, enabled: true, onPressed: () {});
        expect(find.byIcon(Icons.filter_alt), findsOneWidget);

        await pumpButton(tester, enabled: false, onPressed: () {});
        expect(find.byIcon(Icons.filter_alt_off), findsOneWidget);
        expect(find.byIcon(Icons.filter_alt), findsNothing);
      },
    );
  });
}
