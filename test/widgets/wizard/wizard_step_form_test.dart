import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/command/command_parameter.dart';
import 'package:cg500_blueteeth_app/widgets/wizard/wizard_step_form.dart';

void main() {
  final hostPortParameter = CommandParameter.hostPort(
    id: 'addr',
    label: 'Server Address',
  );

  final dropdownParameter = CommandParameter.dropdown(
    id: 'apn',
    label: 'APN',
    dropdownOptions: const [
      DropdownOption(label: 'Internet', value: 'internet'),
      DropdownOption(label: 'IoT', value: 'internet.iot'),
    ],
  );

  Widget wrap({
    required CommandParameter parameter,
    String? initialValue,
    String? currentDeviceValue,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: WizardStepForm(
          stepIndex: 0,
          totalSteps: 1,
          title: 'Test Step',
          parameter: parameter,
          onChanged: (_) {},
          initialValue: initialValue,
          currentDeviceValue: currentDeviceValue,
          isFirst: true,
          isLast: true,
          onNext: () {},
        ),
      ),
    );
  }

  FilledButton nextButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  group('WizardStepForm host:port validation gating', () {
    // Regression cover for the HIGH: 下一步/確認執行 used to be wired
    // straight to onNext with no validation, so a mistyped ADR/FTPADDR
    // (bad port, malformed host) reached the device unfiltered.
    testWidgets('next is enabled once a valid host:port is entered',
        (tester) async {
      await tester.pumpWidget(wrap(parameter: hostPortParameter));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'example.com');
      await tester.enterText(find.byType(TextField).at(1), '9000');
      await tester.pump();

      expect(nextButton(tester).onPressed, isNotNull);
    });

    testWidgets('next is disabled for an out-of-range port (0)',
        (tester) async {
      await tester.pumpWidget(wrap(parameter: hostPortParameter));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'example.com');
      await tester.enterText(find.byType(TextField).at(1), '0');
      await tester.pump();

      expect(nextButton(tester).onPressed, isNull);
      // The disabled button must not be the only signal — the field-level
      // error explaining *why* must be visible too.
      expect(find.text('Port 必須在 1-65535 之間'), findsOneWidget);
    });

    testWidgets('next is disabled when the host is left empty',
        (tester) async {
      await tester.pumpWidget(wrap(parameter: hostPortParameter));
      await tester.pumpAndSettle();

      // Only fill in the port; the host field is left untouched (blank).
      await tester.enterText(find.byType(TextField).at(1), '8080');
      await tester.pump();

      expect(nextButton(tester).onPressed, isNull);
      expect(find.text('主機位址不可為空'), findsOneWidget);
    });

    testWidgets('next re-enables once an invalid value is corrected',
        (tester) async {
      await tester.pumpWidget(wrap(parameter: hostPortParameter));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'example.com');
      await tester.enterText(find.byType(TextField).at(1), '0');
      await tester.pump();
      expect(
        nextButton(tester).onPressed,
        isNull,
        reason: 'an out-of-range port must block next',
      );

      await tester.enterText(find.byType(TextField).at(1), '9000');
      await tester.pump();
      expect(
        nextButton(tester).onPressed,
        isNotNull,
        reason: 'the button must recover once the value becomes valid',
      );
      expect(find.text('Port 必須在 1-65535 之間'), findsNothing);
    });

    testWidgets(
        'next is enabled before the user has typed anything (untouched step)',
        (tester) async {
      await tester.pumpWidget(wrap(parameter: hostPortParameter));
      await tester.pumpAndSettle();

      expect(nextButton(tester).onPressed, isNotNull);
    });

    testWidgets(
      'next stays enabled for an unchanged pre-filled value even if it '
      'would fail validation (ADR-0006: unchanged steps send nothing, so '
      'an untouched device-reported value must never block navigation)',
      (tester) async {
        // '999' is not a valid IP octet — a real device could still report
        // it, and the step must not gate on a value the user never typed.
        const deviceReportedValue = '192.168.1.999:80';
        await tester.pumpWidget(wrap(
          parameter: hostPortParameter,
          initialValue: deviceReportedValue,
          currentDeviceValue: deviceReportedValue,
        ));
        await tester.pumpAndSettle();

        expect(nextButton(tester).onPressed, isNotNull);
      },
    );

    testWidgets(
      'next blocks once the user edits an unchanged-but-invalid pre-filled '
      'value into a still-invalid one',
      (tester) async {
        const deviceReportedValue = '192.168.1.999:80';
        await tester.pumpWidget(wrap(
          parameter: hostPortParameter,
          initialValue: deviceReportedValue,
          currentDeviceValue: deviceReportedValue,
        ));
        await tester.pumpAndSettle();

        // Touch the port field so the step is no longer "unchanged" —
        // now the (still bad) host must be validated.
        await tester.enterText(find.byType(TextField).at(1), '81');
        await tester.pump();

        expect(nextButton(tester).onPressed, isNull);
        expect(find.text('IP 位址格式錯誤'), findsOneWidget);
      },
    );
  });

  group('WizardStepForm dropdown unmatched device value', () {
    testWidgets(
      'no option is pre-selected and a warning is shown when the device '
      'value is not in the option list',
      (tester) async {
        const deviceValue = 'internet.custom';
        await tester.pumpWidget(wrap(
          parameter: dropdownParameter,
          initialValue: deviceValue,
          currentDeviceValue: deviceValue,
        ));
        await tester.pumpAndSettle();

        // Neither option card renders its "selected" check indicator.
        expect(find.byIcon(Icons.check), findsNothing);
        expect(
          find.text('目前裝置回報的值「$deviceValue」不在可選清單中'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a device value that does match an option is pre-selected with no '
      'warning',
      (tester) async {
        await tester.pumpWidget(wrap(
          parameter: dropdownParameter,
          initialValue: 'internet.iot',
          currentDeviceValue: 'internet.iot',
        ));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(
          find.textContaining('不在可選清單中'),
          findsNothing,
        );
      },
    );
  });
}
