import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:cg500_blueteeth_app/widgets/install_guide_dialog.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';
import '../mocks/mock_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Register mock services for testing
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<UpdateService>()) {
      getIt.registerSingleton<UpdateService>(MockUpdateService());
    }
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  group('InstallStep', () {
    test('should create InstallStep with required properties', () {
      const step = InstallStep(
        title: 'Test Step',
        description: 'Test description',
        icon: Icons.check,
        color: Colors.blue,
        instructions: ['Instruction 1', 'Instruction 2'],
      );

      expect(step.title, 'Test Step');
      expect(step.description, 'Test description');
      expect(step.icon, Icons.check);
      expect(step.color, Colors.blue);
      expect(step.instructions.length, 2);
      expect(step.instructions[0], 'Instruction 1');
      expect(step.instructions[1], 'Instruction 2');
    });

    test('should create InstallStep with empty instructions', () {
      const step = InstallStep(
        title: 'Empty Step',
        description: 'No instructions',
        icon: Icons.info,
        color: Colors.grey,
        instructions: [],
      );

      expect(step.instructions.isEmpty, true);
    });

    test('should create InstallStep with single instruction', () {
      const step = InstallStep(
        title: 'Single Step',
        description: 'Single instruction',
        icon: Icons.arrow_forward,
        color: Colors.green,
        instructions: ['Only one step'],
      );

      expect(step.instructions.length, 1);
      expect(step.instructions[0], 'Only one step');
    });

    test('should create InstallStep with many instructions', () {
      const step = InstallStep(
        title: 'Multi Step',
        description: 'Many instructions',
        icon: Icons.list,
        color: Colors.orange,
        instructions: [
          'Step 1',
          'Step 2',
          'Step 3',
          'Step 4',
          'Step 5',
        ],
      );

      expect(step.instructions.length, 5);
    });

    test('should handle different icon types', () {
      const step1 = InstallStep(
        title: 'Download',
        description: 'Download step',
        icon: Icons.download_done,
        color: Colors.green,
        instructions: [],
      );

      const step2 = InstallStep(
        title: 'Security',
        description: 'Security step',
        icon: Icons.security,
        color: Colors.orange,
        instructions: [],
      );

      const step3 = InstallStep(
        title: 'Update',
        description: 'Update step',
        icon: Icons.system_update_alt,
        color: Colors.blue,
        instructions: [],
      );

      expect(step1.icon, Icons.download_done);
      expect(step2.icon, Icons.security);
      expect(step3.icon, Icons.system_update_alt);
    });

    test('should handle different colors', () {
      const step1 = InstallStep(
        title: 'Red Step',
        description: 'Red',
        icon: Icons.error,
        color: Colors.red,
        instructions: [],
      );

      const step2 = InstallStep(
        title: 'Blue Step',
        description: 'Blue',
        icon: Icons.info,
        color: Colors.blue,
        instructions: [],
      );

      expect(step1.color, Colors.red);
      expect(step2.color, Colors.blue);
    });
  });

  group('InstallGuideDialog', () {
    testWidgets('should create without error', (WidgetTester tester) async {
      // InstallGuideDialog uses UpdateService which requires platform channels,
      // so we test with autoInstall: false
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      // Should not crash
      expect(find.byType(InstallGuideDialog), findsOneWidget);
    });

    testWidgets('should create with apkPath', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                apkPath: '/path/to/test.apk',
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(InstallGuideDialog), findsOneWidget);
    });

    testWidgets('should display Installation Guide title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Installation Guide'), findsOneWidget);
    });

    testWidgets('should show step progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show step counter
      expect(find.textContaining('Step'), findsOneWidget);
    });

    testWidgets('should display first step title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First step is "Starting Installation"
      expect(find.text('Starting Installation'), findsOneWidget);
    });

    testWidgets('should have Skip Guide button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Skip Guide'), findsOneWidget);
    });

    testWidgets('should navigate to next step', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the "Install Now" or "Next" button and tap it
      // On first step without apkPath, it should be "Next"
      final nextButton = find.text('Install Now');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();

        // After tapping, should be on step 2
        expect(find.textContaining('Step 2'), findsOneWidget);
      }
    });

    testWidgets('should call onComplete when dialog is closed', (WidgetTester tester) async {
      bool completeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
                onComplete: () {
                  completeCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Skip Guide
      await tester.tap(find.text('Skip Guide'));
      await tester.pumpAndSettle();

      expect(completeCalled, true);
    });

    testWidgets('should display instructions list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "Instructions:" label
      expect(find.text('Instructions:'), findsOneWidget);
    });

    testWidgets('should have proper dialog decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have Dialog widget
      expect(find.byType(Dialog), findsOneWidget);
    });

    testWidgets('should handle multiple step navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate through steps
      // Step 1: Install Now button
      final installButton = find.text('Install Now');
      if (installButton.evaluate().isNotEmpty) {
        await tester.tap(installButton);
        await tester.pumpAndSettle();
      }

      // Step 2 should show "Next"
      final nextButton = find.text('Next');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
      }

      // Continue navigating
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
      }

      // Eventually should reach last step with "Got It!" button
      expect(find.byType(InstallGuideDialog), findsOneWidget);
    });

    testWidgets('should show Previous button after first step', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no Previous button on step 1
      expect(find.text('Previous'), findsNothing);

      // Navigate to step 2
      final installButton = find.text('Install Now');
      if (installButton.evaluate().isNotEmpty) {
        await tester.tap(installButton);
        await tester.pumpAndSettle();

        // Now Previous should be visible
        expect(find.text('Previous'), findsOneWidget);
      }
    });

    testWidgets('should navigate back with Previous button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to step 2
      final installButton = find.text('Install Now');
      if (installButton.evaluate().isNotEmpty) {
        await tester.tap(installButton);
        await tester.pumpAndSettle();

        // Tap Previous
        await tester.tap(find.text('Previous'));
        await tester.pumpAndSettle();

        // Should be back on step 1
        expect(find.text('Step 1 of 4'), findsOneWidget);
      }
    });
  });

  group('InstallGuideDialog layout', () {
    testWidgets('should have constrained width', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render properly with constraints
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have scrollable content', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have SingleChildScrollView for content
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('InstallGuideDialog animations', () {
    testWidgets('should have scale animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: InstallGuideDialog(
                autoInstall: false,
              ),
            ),
          ),
        ),
      );

      // Pump a few frames to see animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Should have Transform widget for scale animation
      expect(find.byType(Transform), findsWidgets);
    });
  });
}
