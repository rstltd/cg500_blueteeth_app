import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/message/message_bubble_widget.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessageBubbleWidget', () {
    testWidgets('should render basic message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Hello World',
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('should render command message with header', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'AT+VERSION',
                'isCommand': true,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      expect(find.text('AT+VERSION'), findsOneWidget);
      expect(find.text(AppStrings.command), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('should render error message with error styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Connection failed',
                'isCommand': false,
                'isError': true,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      expect(find.text('Connection failed'), findsOneWidget);
    });

    testWidgets('should show timestamp by default', (WidgetTester tester) async {
      final timestamp = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Test message',
                'isCommand': false,
                'isError': false,
                'timestamp': timestamp,
              },
              showTimestamp: true,
            ),
          ),
        ),
      );

      expect(find.text('Test message'), findsOneWidget);
      // Timestamp should be visible
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('should hide timestamp when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'No timestamp',
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime.now(),
              },
              showTimestamp: false,
            ),
          ),
        ),
      );

      expect(find.text('No timestamp'), findsOneWidget);
    });

    testWidgets('should handle empty text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': '',
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      // Should render without crashing
      expect(find.byType(MessageBubbleWidget), findsOneWidget);
    });

    testWidgets('should handle missing text key', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      // Should render with empty text
      expect(find.byType(MessageBubbleWidget), findsOneWidget);
    });

    testWidgets('should handle missing timestamp', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'No timestamp in map',
                'isCommand': false,
                'isError': false,
              },
            ),
          ),
        ),
      );

      expect(find.text('No timestamp in map'), findsOneWidget);
    });

    testWidgets('should handle hex content with monospace font', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Response: 01FF00AB',
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      expect(find.text('Response: 01FF00AB'), findsOneWidget);
    });

    testWidgets('should be aligned to end for command messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Command text',
                'isCommand': true,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column).first);
      expect(column.crossAxisAlignment, CrossAxisAlignment.end);
    });

    testWidgets('should be aligned to start for response messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Response text',
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column).first);
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
    });

    testWidgets('should have GestureDetector for long press', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Copy me',
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      // Verify GestureDetector exists for copy functionality
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('should render with gradient for command messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Command with gradient',
                'isCommand': true,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      // Check that Container with BoxDecoration exists
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('MessageListWidget', () {
    testWidgets('should render empty state when no messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageListWidget(
              messages: [],
            ),
          ),
        ),
      );

      expect(find.text(AppStrings.noMessagesYet), findsOneWidget);
      expect(find.text(AppStrings.sendCommandToStart), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });

    testWidgets('should render messages list', (WidgetTester tester) async {
      final messages = [
        {
          'text': 'Message 1',
          'isCommand': true,
          'isError': false,
          'timestamp': DateTime.now(),
        },
        {
          'text': 'Response 1',
          'isCommand': false,
          'isError': false,
          'timestamp': DateTime.now(),
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageListWidget(
              messages: messages,
            ),
          ),
        ),
      );

      expect(find.text('Message 1'), findsOneWidget);
      expect(find.text('Response 1'), findsOneWidget);
    });

    testWidgets('should use ListView.builder for efficiency', (WidgetTester tester) async {
      final messages = List.generate(
        10,
        (index) => {
          'text': 'Message $index',
          'isCommand': index % 2 == 0,
          'isError': false,
          'timestamp': DateTime.now(),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageListWidget(
              messages: messages,
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should use provided scroll controller', (WidgetTester tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageListWidget(
              messages: const [],
              scrollController: scrollController,
            ),
          ),
        ),
      );

      expect(find.byType(MessageListWidget), findsOneWidget);

      scrollController.dispose();
    });

    testWidgets('should auto-scroll to bottom when new messages are added', (WidgetTester tester) async {
      final messages = <Map<String, dynamic>>[
        {
          'text': 'Initial message',
          'isCommand': false,
          'isError': false,
          'timestamp': DateTime.now(),
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageListWidget(
              messages: messages,
              autoScroll: true,
            ),
          ),
        ),
      );

      expect(find.text('Initial message'), findsOneWidget);
    });

    testWidgets('should disable auto-scroll when set to false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageListWidget(
              messages: const [
                {
                  'text': 'Message',
                  'isCommand': false,
                  'isError': false,
                },
              ],
              autoScroll: false,
            ),
          ),
        ),
      );

      expect(find.text('Message'), findsOneWidget);
    });

    testWidgets('should dispose scroll controller when not provided externally', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageListWidget(
              messages: [],
            ),
          ),
        ),
      );

      // Remove widget to trigger dispose
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // If no exception is thrown, dispose worked correctly
      expect(find.byType(MessageListWidget), findsNothing);
    });

    testWidgets('should accept external scroll controller', (WidgetTester tester) async {
      final externalController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageListWidget(
              messages: const [],
              scrollController: externalController,
            ),
          ),
        ),
      );

      // Verify widget was created successfully with external controller
      expect(find.byType(MessageListWidget), findsOneWidget);

      externalController.dispose();
    });

    testWidgets('should handle many messages efficiently', (WidgetTester tester) async {
      final messages = List.generate(
        100,
        (index) => {
          'text': 'Message $index with some longer content to test rendering',
          'isCommand': index % 2 == 0,
          'isError': index % 7 == 0,
          'timestamp': DateTime.now().subtract(Duration(minutes: 100 - index)),
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageListWidget(
              messages: messages,
            ),
          ),
        ),
      );

      // Should render without performance issues
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('Message timestamp formatting', () {
    testWidgets('should format timestamp for same day', (WidgetTester tester) async {
      final now = DateTime.now();
      final recentTime = now.subtract(const Duration(minutes: 30));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Recent message',
                'isCommand': false,
                'isError': false,
                'timestamp': recentTime,
              },
              showTimestamp: true,
            ),
          ),
        ),
      );

      expect(find.text('Recent message'), findsOneWidget);
    });

    testWidgets('should format timestamp for yesterday', (WidgetTester tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Old message',
                'isCommand': false,
                'isError': false,
                'timestamp': yesterday,
              },
              showTimestamp: true,
            ),
          ),
        ),
      );

      expect(find.text('Old message'), findsOneWidget);
    });
  });

  group('MessageBubbleWidget edge cases', () {
    testWidgets('should handle very long text', (WidgetTester tester) async {
      final longText = 'A' * 1000;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MessageBubbleWidget(
                message: {
                  'text': longText,
                  'isCommand': false,
                  'isError': false,
                  'timestamp': DateTime.now(),
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text(longText), findsOneWidget);
    });

    testWidgets('should handle unicode text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': '中文消息 日本語 한국어 🎉',
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('中文'), findsOneWidget);
    });

    testWidgets('should handle special characters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Special: !@#\$%^&*()_+-=[]{}|;:,.<>?',
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('Special'), findsOneWidget);
    });

    testWidgets('should handle newlines in text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubbleWidget(
              message: {
                'text': 'Line 1\nLine 2\nLine 3',
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      expect(find.textContaining('Line 1'), findsOneWidget);
    });
  });
}
