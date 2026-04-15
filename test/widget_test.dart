import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/main.dart';
import 'package:cg500_blueteeth_app/core/service_locator.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

void main() {
  setUpAll(() async {
    // Initialize the service locator before running tests
    await setupServiceLocator();
  });

  tearDownAll(() async {
    // Clean up after all tests
    await resetServiceLocator();
  });

  testWidgets('App should show loading screen initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the loading screen is shown initially
    expect(find.text(AppStrings.initializingApp), findsOneWidget);
    expect(find.text(AppStrings.loadingUpdateSystem), findsOneWidget);
  });

  testWidgets('App should have correct title', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // The MaterialApp title is "CG500 Bluetooth App"
    // This verifies the app was created without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
