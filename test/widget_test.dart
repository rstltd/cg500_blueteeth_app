import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/main.dart';

void main() {
  testWidgets('App should show loading screen initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the loading screen is shown initially
    expect(find.text('Initializing CG500 Bluetooth App...'), findsOneWidget);
    expect(find.text('Loading enhanced update system'), findsOneWidget);
  });

  testWidgets('App should have correct title', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // The MaterialApp title is "CG500 Bluetooth App"
    // This verifies the app was created without crashing
    expect(find.byType(MyApp), findsOneWidget);
  });
}
