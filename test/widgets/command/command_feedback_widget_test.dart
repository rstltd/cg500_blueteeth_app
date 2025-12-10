import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/command/command_feedback_widget.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

void main() {
  group('CommandResult enum', () {
    test('should have 3 values', () {
      expect(CommandResult.values.length, 3);
    });

    test('should contain success', () {
      expect(CommandResult.values, contains(CommandResult.success));
    });

    test('should contain failure', () {
      expect(CommandResult.values, contains(CommandResult.failure));
    });

    test('should contain pending', () {
      expect(CommandResult.values, contains(CommandResult.pending));
    });
  });

  group('CommandFeedbackOverlay widget', () {
    testWidgets('should render success state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackOverlay(
              result: CommandResult.success,
              duration: const Duration(seconds: 10), // Long duration to prevent auto-dismiss
            ),
          ),
        ),
      );
      await tester.pump(); // Start animation

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text(AppStrings.commandSentSuccess), findsOneWidget);

      // Cleanup pending timers
      await tester.pumpAndSettle();
    });

    testWidgets('should render failure state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackOverlay(
              result: CommandResult.failure,
              duration: const Duration(seconds: 10),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text(AppStrings.commandSendFailed), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should render pending state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackOverlay(
              result: CommandResult.pending,
              duration: const Duration(seconds: 10),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
      expect(find.text(AppStrings.sendingCommand), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should display custom message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackOverlay(
              result: CommandResult.success,
              message: 'Custom success message',
              duration: const Duration(seconds: 10),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Custom success message'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should display command text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackOverlay(
              result: CommandResult.success,
              command: '\$ADDR 192.168.1.1 8080',
              duration: const Duration(seconds: 10),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('\$ADDR 192.168.1.1 8080'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should have animation widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackOverlay(
              result: CommandResult.success,
              duration: const Duration(seconds: 10),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should call onDismissed after duration', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackOverlay(
              result: CommandResult.success,
              duration: const Duration(milliseconds: 100),
              onDismissed: () => dismissed = true,
            ),
          ),
        ),
      );

      expect(dismissed, false);

      // Wait for duration + animation
      await tester.pumpAndSettle();

      expect(dismissed, true);
    });
  });

  group('CommandFeedbackOverlay.showSnackBar', () {
    testWidgets('should show success snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CommandFeedbackOverlay.showSnackBar(
                    context,
                    result: CommandResult.success,
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(AppStrings.commandSentSuccess), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show failure snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CommandFeedbackOverlay.showSnackBar(
                    context,
                    result: CommandResult.failure,
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(AppStrings.commandSendFailed), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should show snackbar with command', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CommandFeedbackOverlay.showSnackBar(
                    context,
                    result: CommandResult.success,
                    command: '\$ADDR 192.168.1.1',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('\$ADDR 192.168.1.1'), findsOneWidget);
    });

    testWidgets('should show snackbar with custom message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CommandFeedbackOverlay.showSnackBar(
                    context,
                    result: CommandResult.success,
                    message: 'Custom message',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Custom message'), findsOneWidget);
    });

    testWidgets('should show pending snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  CommandFeedbackOverlay.showSnackBar(
                    context,
                    result: CommandResult.pending,
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(AppStrings.sendingCommand), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });
  });

  group('CommandFeedbackIndicator', () {
    testWidgets('should render success indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackIndicator(
              result: CommandResult.success,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should render failure indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackIndicator(
              result: CommandResult.failure,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should render pending indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackIndicator(
              result: CommandResult.pending,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
    });

    testWidgets('should be hidden when visible is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackIndicator(
              result: CommandResult.success,
              visible: false,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    testWidgets('should use custom size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackIndicator(
              result: CommandResult.success,
              size: 32,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.size, 32);
    });

    testWidgets('should animate opacity', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommandFeedbackIndicator(
              result: CommandResult.success,
              visible: true,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedOpacity), findsOneWidget);
    });
  });

  group('CommandFeedbackExtension', () {
    testWidgets('showCommandSuccess should show success snackbar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  context.showCommandSuccess(
                    command: '\$ADDR',
                    message: 'Address set',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('showCommandFailure should show failure snackbar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  context.showCommandFailure(
                    command: '\$ADDR',
                    message: 'Failed to set address',
                  );
                },
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });
  });
}
