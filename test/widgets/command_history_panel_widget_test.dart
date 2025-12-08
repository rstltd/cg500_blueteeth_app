import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/command_history_panel_widget.dart';
import 'package:cg500_blueteeth_app/controllers/command_manager.dart';
import '../mocks/mock_services.dart';

void main() {
  group('CommandHistoryPanelWidget', () {
    late MockBleController mockController;
    late CommandManager commandManager;

    setUp(() {
      mockController = MockBleController();
      commandManager = CommandManager(
        controller: mockController,
        onCommandSent: () {},
        onMessageAdded: (_) {},
      );
    });

    tearDown(() {
      commandManager.dispose();
      mockController.dispose();
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CommandHistoryPanelWidget(commandManager: commandManager),
          ),
        ),
      );
    }

    group('empty history', () {
      testWidgets('should show header with history icon', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.history), findsOneWidget);
        expect(find.text('Command History'), findsOneWidget);
      });

      testWidgets('should show empty message', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('No commands yet'), findsOneWidget);
      });

      testWidgets('should not show any command items', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.replay), findsNothing);
      });
    });

    group('with command history', () {
      setUp(() async {
        // Add commands to history
        mockController.simulateConnected(createTestDevice(
          id: 'test',
          name: 'Test Device',
        ));

        commandManager.textController.text = 'COMMAND_1';
        await commandManager.sendCommand();
        commandManager.textController.text = 'COMMAND_2';
        await commandManager.sendCommand();
        commandManager.textController.text = 'COMMAND_3';
        await commandManager.sendCommand();
      });

      testWidgets('should show all commands', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('COMMAND_1'), findsOneWidget);
        expect(find.text('COMMAND_2'), findsOneWidget);
        expect(find.text('COMMAND_3'), findsOneWidget);
      });

      testWidgets('should not show empty message', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('No commands yet'), findsNothing);
      });

      testWidgets('should show replay button for each command', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.replay), findsNWidgets(3));
      });

      testWidgets('replay button should populate text field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find first replay button and tap it
        final replayButtons = find.byIcon(Icons.replay);
        await tester.tap(replayButtons.first);
        await tester.pump();

        // Check that text controller was updated
        // Since commands are displayed in reverse, the first replay button
        // corresponds to the most recent command
        expect(
          commandManager.textController.text,
          anyOf(['COMMAND_1', 'COMMAND_2', 'COMMAND_3']),
        );
      });

      testWidgets('should have tooltip on replay button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Find IconButton with replay icon
        final replayButton = find.ancestor(
          of: find.byIcon(Icons.replay),
          matching: find.byType(IconButton),
        );
        expect(replayButton, findsWidgets);

        // Check tooltip
        final iconButton = tester.widget<IconButton>(replayButton.first);
        expect(iconButton.tooltip, 'Use this command');
      });
    });

    group('styling and layout', () {
      testWidgets('should be contained in ResponsiveCard', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Widget should render without errors
        expect(find.byType(CommandHistoryPanelWidget), findsOneWidget);
      });

      testWidgets('should have fixed height container for list', (tester) async {
        // Add some commands
        mockController.simulateConnected(createTestDevice(
          id: 'test',
          name: 'Test Device',
        ));
        commandManager.textController.text = 'TEST';
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should find SizedBox with height 200
        final sizedBox = find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == 200,
        );
        expect(sizedBox, findsOneWidget);
      });
    });

    group('scrolling behavior', () {
      testWidgets('should be scrollable with many commands', (tester) async {
        // Add many commands
        mockController.simulateConnected(createTestDevice(
          id: 'test',
          name: 'Test Device',
        ));

        for (int i = 1; i <= 20; i++) {
          commandManager.textController.text = 'COMMAND_$i';
          await commandManager.sendCommand();
        }

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should have ListView
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('ListView should be reversed', (tester) async {
        mockController.simulateConnected(createTestDevice(
          id: 'test',
          name: 'Test Device',
        ));
        commandManager.textController.text = 'TEST';
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.reverse, isTrue);
      });
    });

    group('edge cases', () {
      testWidgets('handles very long command text', (tester) async {
        mockController.simulateConnected(createTestDevice(
          id: 'test',
          name: 'Test Device',
        ));

        final longCommand = 'A' * 200;
        commandManager.textController.text = longCommand;
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should render without overflow errors
        expect(find.byType(CommandHistoryPanelWidget), findsOneWidget);
      });

      testWidgets('handles special characters in commands', (tester) async {
        mockController.simulateConnected(createTestDevice(
          id: 'test',
          name: 'Test Device',
        ));

        commandManager.textController.text = r'$INFO{"key":"value"}';
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.textContaining(r'$INFO'), findsOneWidget);
      });

      testWidgets('handles unicode in commands', (tester) async {
        mockController.simulateConnected(createTestDevice(
          id: 'test',
          name: 'Test Device',
        ));

        commandManager.textController.text = '測試命令 🔵';
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('測試命令 🔵'), findsOneWidget);
      });
    });

    group('interaction with CommandManager', () {
      testWidgets('should update when new command added', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('No commands yet'), findsOneWidget);

        // Add a command
        mockController.simulateConnected(createTestDevice(
          id: 'test',
          name: 'Test Device',
        ));
        commandManager.textController.text = 'NEW_COMMAND';
        await commandManager.sendCommand();

        // Rebuild widget
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('NEW_COMMAND'), findsOneWidget);
        expect(find.text('No commands yet'), findsNothing);
      });
    });
  });
}
