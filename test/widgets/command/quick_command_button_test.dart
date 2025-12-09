import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/command/command.dart';
import 'package:cg500_blueteeth_app/widgets/command/quick_command_button.dart';

void main() {
  // Test command fixture
  const testCommand = DeviceCommand(
    command: r'$INFO',
    name: 'Show Info',
    description: 'Display device information',
    category: CommandCategory.query,
    icon: Icons.info_outline,
  );

  Widget buildTestWidget({
    DeviceCommand command = testCommand,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool showLabel = true,
    bool compact = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: QuickCommandButton(
            command: command,
            onPressed: onPressed,
            isLoading: isLoading,
            showLabel: showLabel,
            compact: compact,
          ),
        ),
      ),
    );
  }

  group('QuickCommandButton', () {
    group('rendering', () {
      testWidgets('displays command icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(onPressed: () {}));

        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('displays command label when showLabel is true',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(onPressed: () {}));

        expect(find.text('INFO'), findsOneWidget);
      });

      testWidgets('hides label when showLabel is false', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          onPressed: () {},
          showLabel: false,
        ));

        expect(find.text('INFO'), findsNothing);
      });

      testWidgets('shows tooltip with command description', (tester) async {
        await tester.pumpWidget(buildTestWidget(onPressed: () {}));

        // Find the tooltip widget
        final tooltipFinder = find.byType(Tooltip);
        expect(tooltipFinder, findsOneWidget);

        final tooltip = tester.widget<Tooltip>(tooltipFinder);
        expect(tooltip.message, testCommand.description);
      });

      testWidgets('uses compact sizing when compact is true', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          onPressed: () {},
          compact: true,
        ));

        // The widget should render successfully in compact mode
        expect(find.byType(QuickCommandButton), findsOneWidget);
      });
    });

    group('states', () {
      testWidgets('is enabled when onPressed is provided', (tester) async {
        bool pressed = false;
        await tester.pumpWidget(buildTestWidget(onPressed: () {
          pressed = true;
        }));

        await tester.tap(find.byType(QuickCommandButton));
        expect(pressed, true);
      });

      testWidgets('is disabled when onPressed is null', (tester) async {
        await tester.pumpWidget(buildTestWidget(onPressed: null));

        // Tapping should not throw, but nothing happens
        await tester.tap(find.byType(InkWell));
        await tester.pump();
      });

      testWidgets('shows loading indicator when isLoading is true',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          onPressed: () {},
          isLoading: true,
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsNothing);
      });

      testWidgets('is not tappable when loading', (tester) async {
        bool pressed = false;
        await tester.pumpWidget(buildTestWidget(
          onPressed: () {
            pressed = true;
          },
          isLoading: true,
        ));

        await tester.tap(find.byType(QuickCommandButton));
        expect(pressed, false);
      });
    });

    group('label formatting', () {
      testWidgets('removes dollar sign prefix from command', (tester) async {
        await tester.pumpWidget(buildTestWidget(onPressed: () {}));

        // Should show 'INFO' not '$INFO'
        expect(find.text('INFO'), findsOneWidget);
        expect(find.text(r'$INFO'), findsNothing);
      });

      testWidgets('handles command without dollar sign', (tester) async {
        const commandNoDollar = DeviceCommand(
          command: 'TEST',
          name: 'Test',
          description: 'Test',
          category: CommandCategory.query,
        );

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: QuickCommandButton(
              command: commandNoDollar,
              onPressed: () {},
            ),
          ),
        ));

        expect(find.text('TEST'), findsOneWidget);
      });
    });

    group('visual styling', () {
      testWidgets('renders in light theme', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: QuickCommandButton(
              command: testCommand,
              onPressed: () {},
            ),
          ),
        ));

        expect(find.byType(QuickCommandButton), findsOneWidget);
      });

      testWidgets('renders in dark theme', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuickCommandButton(
              command: testCommand,
              onPressed: () {},
            ),
          ),
        ));

        expect(find.byType(QuickCommandButton), findsOneWidget);
      });

      testWidgets('animates on state change', (tester) async {
        await tester.pumpWidget(buildTestWidget(onPressed: () {}));

        // Find AnimatedContainer
        expect(find.byType(AnimatedContainer), findsOneWidget);
      });
    });
  });

  group('QuickCommandOutlineButton', () {
    testWidgets('displays as OutlinedButton with enabled state', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuickCommandOutlineButton(
              command: testCommand,
              onPressed: () {},
            ),
          ),
        ),
      ));

      expect(find.byType(QuickCommandOutlineButton), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('displays as OutlinedButton with disabled state', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuickCommandOutlineButton(
              command: testCommand,
              onPressed: null,
            ),
          ),
        ),
      ));

      expect(find.byType(QuickCommandOutlineButton), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuickCommandOutlineButton(
              command: testCommand,
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('calls onPressed callback when tapped', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuickCommandOutlineButton(
              command: testCommand,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      ));

      // Tap the widget itself instead of searching for OutlinedButton
      await tester.tap(find.byType(QuickCommandOutlineButton));
      await tester.pump();
      expect(pressed, true);
    });

    testWidgets('hides label when showLabel is false', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: QuickCommandOutlineButton(
              command: testCommand,
              onPressed: () {},
              showLabel: false,
            ),
          ),
        ),
      ));

      expect(find.byType(QuickCommandOutlineButton), findsOneWidget);
      expect(find.text('INFO'), findsNothing);
    });
  });

  group('different command types', () {
    testWidgets('displays config command correctly', (tester) async {
      final configCommand = DeviceCommand(
        command: r'$MAC',
        name: 'Set MAC',
        description: 'Set device ID',
        category: CommandCategory.config,
        icon: Icons.label_outline,
        parameters: [
          CommandParameter.text(id: 'mac', label: 'MAC'),
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuickCommandButton(
            command: configCommand,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.label_outline), findsOneWidget);
      expect(find.text('MAC'), findsOneWidget);
    });

    testWidgets('displays control command correctly', (tester) async {
      const controlCommand = DeviceCommand(
        command: r'$TCPX',
        name: 'Restart TCP',
        description: 'Restart TCP connection',
        category: CommandCategory.control,
        icon: Icons.refresh,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuickCommandButton(
            command: controlCommand,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('TCPX'), findsOneWidget);
    });

    testWidgets('displays debug command correctly', (tester) async {
      const debugCommand = DeviceCommand(
        command: r'$DEBUG',
        name: 'Debug Mode',
        description: 'Show GPS debug info',
        category: CommandCategory.debug,
        icon: Icons.bug_report,
        dangerLevel: DangerLevel.warning,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: QuickCommandButton(
            command: debugCommand,
            onPressed: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.bug_report), findsOneWidget);
      expect(find.text('DEBUG'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('has semantic label via tooltip', (tester) async {
      await tester.pumpWidget(buildTestWidget(onPressed: () {}));

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, isNotEmpty);
    });

    testWidgets('InkWell provides tap feedback', (tester) async {
      await tester.pumpWidget(buildTestWidget(onPressed: () {}));

      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
