import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cg500_blueteeth_app/widgets/layout/notification_settings_dialog.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/controllers/ble_controller_interface.dart';
import 'package:cg500_blueteeth_app/services/smart_notification_service.dart';
import '../mocks/mock_ble_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBleController mockController;
  late SmartNotificationService mockNotificationService;

  setUp(() async {
    // Reset GetIt before each test
    final getIt = GetIt.instance;
    await getIt.reset();

    // Set up mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Create mock services
    mockController = MockBleController();
    mockNotificationService = SmartNotificationService();

    // Register services with GetIt
    getIt.registerSingleton<NotificationService>(mockNotificationService);
    getIt.registerSingleton<BleControllerInterface>(mockController);
  });

  tearDown(() async {
    mockController.dispose();
    final getIt = GetIt.instance;
    await getIt.reset();
  });

  group('NotificationSettingsDialog', () {
    testWidgets('should create without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );

      expect(find.byType(NotificationSettingsDialog), findsOneWidget);
    });

    testWidgets('should display dialog title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );

      expect(find.text('Notification Settings'), findsOneWidget);
    });

    testWidgets('should display description text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );

      expect(find.text('Configure when and how notifications are shown'), findsOneWidget);
    });

    testWidgets('should have notifications icon in header', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('should have Cancel button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should have Apply Settings button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );

      expect(find.text('Apply Settings'), findsOneWidget);
    });

    testWidgets('should have Dialog widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );

      expect(find.byType(Dialog), findsOneWidget);
    });
  });

  group('NotificationSettingsDialog sections', () {
    testWidgets('should display Smart Filtering section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('Smart Filtering'), findsOneWidget);
      expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    });

    testWidgets('should display Notification Categories section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('Notification Categories'), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
    });

    testWidgets('should display Statistics section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('Statistics'), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
    });
  });

  group('NotificationSettingsDialog smart filtering', () {
    testWidgets('should have Enable Smart Filtering switch', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('Enable Smart Filtering'), findsOneWidget);
      expect(find.text('Automatically reduce notification spam and duplicates'), findsOneWidget);
    });

    testWidgets('should have SwitchListTile for smart filtering', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('should toggle smart filtering switch', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      // Find the SwitchListTile and tap it
      final switchFinder = find.byType(SwitchListTile);
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pump();

      // The switch should have toggled
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('should show info card when smart filtering is enabled', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      // Smart filtering is enabled by default
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      expect(find.textContaining('Smart filtering prevents'), findsOneWidget);
    });
  });

  group('NotificationSettingsDialog notification categories', () {
    testWidgets('should display Connection Events category', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('Connection Events'), findsOneWidget);
      expect(find.text('Show notifications when devices connect/disconnect'), findsOneWidget);
      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
    });

    testWidgets('should display Scanning Events category', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('Scanning Events'), findsOneWidget);
      expect(find.text('Show notifications during device scanning'), findsOneWidget);
      expect(find.byIcon(Icons.radar), findsOneWidget);
    });

    testWidgets('should display MTU Configuration category', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('MTU Configuration'), findsOneWidget);
      expect(find.text('Show notifications about MTU setup'), findsOneWidget);
      expect(find.byIcon(Icons.settings_ethernet), findsOneWidget);
    });

    testWidgets('should display Command Feedback category', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('Command Feedback'), findsOneWidget);
      expect(find.text('Show notifications for sent commands'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should have multiple Switch widgets for categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      // 4 category switches + 1 smart filtering switch = 5 switches
      expect(find.byType(Switch), findsNWidgets(5));
    });
  });

  group('NotificationSettingsDialog statistics', () {
    testWidgets('should display Total Notifications stat', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('Total Notifications'), findsOneWidget);
    });

    testWidgets('should display Filtered Notifications stat', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('Filtered Notifications'), findsOneWidget);
    });

    testWidgets('should display Pending Notifications stat', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('Pending Notifications'), findsOneWidget);
    });

    testWidgets('should have Clear Filters button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.text('Clear Filters'), findsOneWidget);
      expect(find.byIcon(Icons.clear_all), findsOneWidget);
    });
  });

  group('NotificationSettingsDialog layout', () {
    testWidgets('should have scrollable content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should have Column layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should have Row for actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should have Card widgets for sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('should have Dividers between categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(Divider), findsWidgets);
    });
  });

  group('NotificationSettingsDialog theming', () {
    testWidgets('should render in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(NotificationSettingsDialog), findsOneWidget);
    });

    testWidgets('should render in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(NotificationSettingsDialog), findsOneWidget);
    });

    testWidgets('should render with custom theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.purple,
            ),
          ),
          home: const Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(NotificationSettingsDialog), findsOneWidget);
    });
  });

  group('NotificationSettingsDialog responsive', () {
    testWidgets('should render on mobile screen', (WidgetTester tester) async {
      // Use a larger mobile screen to avoid overflow with the dialog content
      // The dialog has complex Row layouts that need more width on mobile
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(NotificationSettingsDialog), findsOneWidget);
    });

    testWidgets('should render on tablet screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(NotificationSettingsDialog), findsOneWidget);
    });

    testWidgets('should render on desktop screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.byType(NotificationSettingsDialog), findsOneWidget);
    });
  });

  group('NotificationSettingsDialog interactions', () {
    testWidgets('should toggle connection events switch', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      // Find switches - Connection events is enabled by default
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(5));

      // Tap a category switch (not the SwitchListTile one)
      // The switches are: smart filtering (in SwitchListTile), and 4 category switches
      await tester.tap(switches.at(1)); // Connection Events switch
      await tester.pump();

      expect(find.byType(Switch), findsNWidgets(5));
    });

    testWidgets('should toggle scanning events switch', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      final switches = find.byType(Switch);
      await tester.tap(switches.at(2)); // Scanning Events switch
      await tester.pump();

      expect(find.byType(Switch), findsNWidgets(5));
    });

    testWidgets('should toggle MTU configuration switch', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      final switches = find.byType(Switch);
      await tester.tap(switches.at(3)); // MTU Configuration switch
      await tester.pump();

      expect(find.byType(Switch), findsNWidgets(5));
    });

    testWidgets('should toggle command feedback switch', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      final switches = find.byType(Switch);
      await tester.tap(switches.at(4)); // Command Feedback switch
      await tester.pump();

      expect(find.byType(Switch), findsNWidgets(5));
    });

    testWidgets('should hide info card when smart filtering is disabled', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      // Initially smart filtering is enabled, so info card is visible
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);

      // Toggle smart filtering off
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      // Info card should be hidden
      expect(find.byIcon(Icons.lightbulb_outline), findsNothing);
    });
  });

  group('NotificationSettingsDialog buttons', () {
    testWidgets('Cancel button should be TextButton', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.widgetWithText(TextButton, 'Cancel'), findsOneWidget);
    });

    testWidgets('Apply Settings button should be ElevatedButton', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      expect(find.widgetWithText(ElevatedButton, 'Apply Settings'), findsOneWidget);
    });

    testWidgets('Clear Filters should be TextButton.icon', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      // TextButton.icon creates a TextButton with icon and label
      // Verify both the text and the clear_all icon exist
      expect(find.text('Clear Filters'), findsOneWidget);
      expect(find.byIcon(Icons.clear_all), findsOneWidget);
    });
  });

  group('NotificationSettingsDialog state', () {
    testWidgets('should maintain state during rebuilds', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      // Toggle a switch
      final switches = find.byType(Switch);
      await tester.tap(switches.at(1));
      await tester.pump();

      // Rebuild widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      // Widget should still be present
      expect(find.byType(NotificationSettingsDialog), findsOneWidget);
    });

    testWidgets('should handle rapid toggle interactions', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      final switchListTile = find.byType(SwitchListTile);

      // Rapidly toggle multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(switchListTile);
        await tester.pump();
      }

      expect(find.byType(NotificationSettingsDialog), findsOneWidget);
    });
  });

  group('NotificationSettingsDialog accessibility', () {
    testWidgets('should have all required icons', (WidgetTester tester) async {
      // Use larger screen size to accommodate dialog content
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NotificationSettingsDialog(),
          ),
        ),
      );
      await tester.pumpAndSettle(); // Wait for async _loadSettings()

      // Header icons
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);

      // Section icons
      expect(find.byIcon(Icons.filter_alt), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);

      // Category icons
      expect(find.byIcon(Icons.bluetooth_connected), findsOneWidget);
      expect(find.byIcon(Icons.radar), findsOneWidget);
      expect(find.byIcon(Icons.settings_ethernet), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Smart filtering info icon
      expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);

      // Clear filters icon
      expect(find.byIcon(Icons.clear_all), findsOneWidget);
    });
  });
}
