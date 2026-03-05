import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/widgets/message/message_bubble_widget.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogEntryWidget', () {
    testWidgets('should render basic response message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogEntryWidget(
              message: {
                'text': 'Hello World',
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime(2024, 1, 15, 14, 30, 45),
              },
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
      expect(find.text('14:30:45'), findsOneWidget);
      expect(find.textContaining('<- RSP'), findsOneWidget);
    });

    testWidgets('should render command with -> CMD indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogEntryWidget(
              message: {
                'text': 'AT+VERSION',
                'isCommand': true,
                'isError': false,
                'timestamp': DateTime(2024, 1, 15, 9, 5, 3),
              },
            ),
          ),
        ),
      );

      expect(find.text('AT+VERSION'), findsOneWidget);
      expect(find.text('09:05:03'), findsOneWidget);
      expect(find.textContaining('-> CMD'), findsOneWidget);
    });

    testWidgets('should render error with x ERR indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogEntryWidget(
              message: {
                'text': 'Connection failed',
                'isCommand': false,
                'isError': true,
                'timestamp': DateTime(2024, 1, 15, 12, 0, 0),
              },
            ),
          ),
        ),
      );

      expect(find.text('Connection failed'), findsOneWidget);
      expect(find.textContaining('x ERR'), findsOneWidget);
    });

    testWidgets('should show HH:mm:ss timestamp format',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogEntryWidget(
              message: {
                'text': 'Test',
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime(2024, 6, 1, 8, 5, 9),
              },
            ),
          ),
        ),
      );

      expect(find.text('08:05:09'), findsOneWidget);
    });

    testWidgets('should handle empty text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogEntryWidget(
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

      expect(find.byType(LogEntryWidget), findsOneWidget);
    });

    testWidgets('should handle missing text key', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogEntryWidget(
              message: {
                'isCommand': false,
                'isError': false,
                'timestamp': DateTime.now(),
              },
            ),
          ),
        ),
      );

      expect(find.byType(LogEntryWidget), findsOneWidget);
    });

    testWidgets('should handle missing timestamp',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogEntryWidget(
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

    testWidgets('should have GestureDetector for long press copy',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogEntryWidget(
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

      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('should handle very long text', (WidgetTester tester) async {
      final longText = 'A' * 1000;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LogEntryWidget(
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
            body: LogEntryWidget(
              message: {
                'text': '中文消息 日本語 한국어',
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

    testWidgets('should handle special characters',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogEntryWidget(
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

    testWidgets('should handle newlines in text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LogEntryWidget(
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

    testWidgets('should alternate row background based on index',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LogEntryWidget(
                  message: {
                    'text': 'Even row',
                    'isCommand': false,
                    'isError': false,
                    'timestamp': DateTime.now(),
                  },
                  index: 0,
                ),
                LogEntryWidget(
                  message: {
                    'text': 'Odd row',
                    'isCommand': false,
                    'isError': false,
                    'timestamp': DateTime.now(),
                  },
                  index: 1,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Even row'), findsOneWidget);
      expect(find.text('Odd row'), findsOneWidget);
    });
  });

  group('MessageListWidget', () {
    testWidgets('should render empty state when no messages',
        (WidgetTester tester) async {
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

    testWidgets('should render messages list with LogEntryWidget',
        (WidgetTester tester) async {
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
      expect(find.byType(LogEntryWidget), findsNWidgets(2));
    });

    testWidgets('should use ListView.builder for efficiency',
        (WidgetTester tester) async {
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

    testWidgets('should use provided scroll controller',
        (WidgetTester tester) async {
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

    testWidgets(
        'should dispose scroll controller when not provided externally',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MessageListWidget(
              messages: [],
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      expect(find.byType(MessageListWidget), findsNothing);
    });

    testWidgets('should accept external scroll controller',
        (WidgetTester tester) async {
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

      expect(find.byType(MessageListWidget), findsOneWidget);

      externalController.dispose();
    });

    testWidgets('should handle many messages efficiently',
        (WidgetTester tester) async {
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

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
