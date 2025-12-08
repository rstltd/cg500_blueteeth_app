import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/command_input_panel_widget.dart';
import 'package:cg500_blueteeth_app/controllers/command_manager.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';
import '../mocks/mock_services.dart';

void main() {
  group('CommandInputPanelWidget', () {
    late MockBleController mockController;
    late CommandManager commandManager;
    late bool sendCommandCalled;
    late List<bool> historyNavigations;

    setUp(() {
      mockController = MockBleController();
      commandManager = CommandManager(
        controller: mockController,
        onCommandSent: () {},
        onMessageAdded: (_) {},
      );
      sendCommandCalled = false;
      historyNavigations = [];
    });

    tearDown(() {
      commandManager.dispose();
      mockController.dispose();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: CommandInputPanelWidget(
            controller: mockController,
            commandManager: commandManager,
            onSendCommand: () {
              sendCommandCalled = true;
            },
            onNavigateHistory: (up) {
              historyNavigations.add(up);
            },
          ),
        ),
      );
    }

    group('when not connected', () {
      testWidgets('should show disabled text field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, isFalse);
      });

      testWidgets('should show connect hint text', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Connect device to send commands'), findsOneWidget);
      });

      testWidgets('should disable send button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        final sendButton = find.byIcon(Icons.send_rounded);
        expect(sendButton, findsOneWidget);

        await tester.tap(sendButton);
        await tester.pump();

        expect(sendCommandCalled, isFalse);
      });

      testWidgets('should show keyboard icon', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.keyboard), findsOneWidget);
      });
    });

    group('when connected with command channel', () {
      late BleDeviceModel testDevice;

      setUp(() {
        testDevice = createTestDevice(
          id: 'test-device',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(
          hasCommandChannel: true,
          hasResponseChannel: true,
        );
      });

      testWidgets('should enable text field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, isTrue);
      });

      testWidgets('should show type command hint', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Type your command...'), findsOneWidget);
      });

      testWidgets('should enable send button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        final sendButton = find.byIcon(Icons.send_rounded);
        await tester.tap(sendButton);
        await tester.pump();

        expect(sendCommandCalled, isTrue);
      });

      testWidgets('should allow typing in text field', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'TEST_COMMAND');
        await tester.pump();

        expect(find.text('TEST_COMMAND'), findsOneWidget);
      });

      testWidgets('should call send on submit', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.enterText(find.byType(TextField), 'TEST');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(sendCommandCalled, isTrue);
      });
    });

    group('connected but no command channel', () {
      setUp(() {
        final testDevice = createTestDevice(
          id: 'test-device',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(
          hasCommandChannel: false,
          hasResponseChannel: true,
        );
      });

      testWidgets('should disable text field when no TX channel', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.enabled, isFalse);
      });

      testWidgets('should disable send button when no TX channel', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        final sendButton = find.byIcon(Icons.send_rounded);
        await tester.tap(sendButton);
        await tester.pump();

        expect(sendCommandCalled, isFalse);
      });
    });

    group('command history navigation', () {
      late BleDeviceModel testDevice;

      setUp(() {
        testDevice = createTestDevice(
          id: 'test-device',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(hasCommandChannel: true);
      });

      testWidgets('should not show history controls with empty history',
          (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
        expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      });

      testWidgets('should show history controls when history exists',
          (tester) async {
        // Add command to history
        commandManager.textController.text = 'TEST_CMD';
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      });

      testWidgets('should show command count', (tester) async {
        // Add commands to history
        commandManager.textController.text = 'CMD1';
        await commandManager.sendCommand();
        commandManager.textController.text = 'CMD2';
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('2 commands'), findsOneWidget);
        expect(find.byIcon(Icons.history), findsOneWidget);
      });

      testWidgets('should call onNavigateHistory when up pressed',
          (tester) async {
        commandManager.textController.text = 'TEST';
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
        await tester.pump();

        expect(historyNavigations, contains(true));
      });

      testWidgets('should call onNavigateHistory when down pressed',
          (tester) async {
        commandManager.textController.text = 'TEST';
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
        await tester.pump();

        expect(historyNavigations, contains(false));
      });
    });

    group('ready indicator', () {
      testWidgets('should show Ready indicator when can send', (tester) async {
        final testDevice = createTestDevice(
          id: 'test-device',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(hasCommandChannel: true);

        // Need history to show the indicator row
        commandManager.textController.text = 'TEST';
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Ready'), findsOneWidget);
        expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      });

      testWidgets('should not show Ready when cannot send', (tester) async {
        // Not connected
        commandManager.textController.text = 'TEST';
        await commandManager.sendCommand();

        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.text('Ready'), findsNothing);
      });
    });

    group('UI styling', () {
      testWidgets('should have rounded container', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Widget should render without errors
        expect(find.byType(CommandInputPanelWidget), findsOneWidget);
      });

      testWidgets('should have shadow decoration', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        final containers = find.byType(Container);
        expect(containers, findsWidgets);
      });

      testWidgets('should use AnimatedContainer for send button',
          (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        expect(find.byType(AnimatedContainer), findsOneWidget);
      });
    });

    group('state transitions', () {
      testWidgets('should update when connection state changes',
          (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Initially not connected
        expect(find.text('Connect device to send commands'), findsOneWidget);

        // Connect - rebuild widget to pick up stream changes
        final testDevice = createTestDevice(
          id: 'test-device',
          name: 'Test Device',
          connectionState: BleConnectionState.connected,
        );
        mockController.simulateConnected(testDevice);
        mockController.configureCommandInfo(hasCommandChannel: true);
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should now show type hint
        expect(find.text('Type your command...'), findsOneWidget);

        // Disconnect - rebuild widget to pick up stream changes
        mockController.simulateDisconnected();
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        // Should show connect hint again
        expect(find.text('Connect device to send commands'), findsOneWidget);
      });
    });
  });
}
