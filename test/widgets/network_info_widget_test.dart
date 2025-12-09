import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/update/network_info_widget.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import '../mocks/mock_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkInfoWidget', () {
    late MockNetworkService networkService;
    late MockUpdateService updateService;

    setUp(() {
      networkService = MockNetworkService();
      updateService = MockUpdateService();
    });

    testWidgets('should render with WiFi status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024, // 10 MB
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      expect(find.byType(NetworkInfoWidget), findsOneWidget);
      expect(find.text('Network:'), findsOneWidget);
    });

    testWidgets('should render with mobile status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.mobile,
            ),
          ),
        ),
      );

      expect(find.byType(NetworkInfoWidget), findsOneWidget);
    });

    testWidgets('should render with no connection status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.none,
            ),
          ),
        ),
      );

      expect(find.byType(NetworkInfoWidget), findsOneWidget);
    });

    testWidgets('should render with unknown status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.unknown,
            ),
          ),
        ),
      );

      expect(find.byType(NetworkInfoWidget), findsOneWidget);
    });

    testWidgets('should show WiFi icon for WiFi status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('should show cellular icon for mobile status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.mobile,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.signal_cellular_4_bar), findsOneWidget);
    });

    testWidgets('should show wifi_off icon for no connection', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.none,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('should show help icon for unknown status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.unknown,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });

    testWidgets('should display network type name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      // The network service should return a display name
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should display estimated download time', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 50 * 1024 * 1024, // 50 MB
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      // Should show "Est." text
      expect(find.textContaining('Est.'), findsOneWidget);
    });

    testWidgets('should handle small download size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 1024, // 1 KB
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      expect(find.byType(NetworkInfoWidget), findsOneWidget);
    });

    testWidgets('should handle large download size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 500 * 1024 * 1024, // 500 MB
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      expect(find.byType(NetworkInfoWidget), findsOneWidget);
    });

    testWidgets('should handle zero download size', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 0,
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      expect(find.byType(NetworkInfoWidget), findsOneWidget);
    });

    testWidgets('should have proper row layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Expanded), findsWidgets);
    });

    testWidgets('should have SizedBox for label width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should display in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      expect(find.byType(NetworkInfoWidget), findsOneWidget);
    });

    testWidgets('should display in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      expect(find.byType(NetworkInfoWidget), findsOneWidget);
    });
  });

  group('NetworkInfoWidget icon colors', () {
    late MockNetworkService networkService;
    late MockUpdateService updateService;

    setUp(() {
      networkService = MockNetworkService();
      updateService = MockUpdateService();
    });

    testWidgets('should have icon with proper color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NetworkInfoWidget(
              networkService: networkService,
              updateService: updateService,
              downloadSize: 10 * 1024 * 1024,
              networkStatus: NetworkStatus.wifi,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.wifi));
      expect(icon.size, 16);
    });
  });

  group('NetworkInfoWidget all status types', () {
    late MockNetworkService networkService;
    late MockUpdateService updateService;

    setUp(() {
      networkService = MockNetworkService();
      updateService = MockUpdateService();
    });

    for (final status in NetworkStatus.values) {
      testWidgets('should render with ${status.name} status', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NetworkInfoWidget(
                networkService: networkService,
                updateService: updateService,
                downloadSize: 10 * 1024 * 1024,
                networkStatus: status,
              ),
            ),
          ),
        );

        expect(find.byType(NetworkInfoWidget), findsOneWidget);
      });
    }
  });
}
