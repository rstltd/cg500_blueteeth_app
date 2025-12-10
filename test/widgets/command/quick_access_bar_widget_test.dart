import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import 'package:cg500_blueteeth_app/models/command/command.dart';
import 'package:cg500_blueteeth_app/repositories/command_repository.dart';
import 'package:cg500_blueteeth_app/widgets/command/quick_access_bar_widget.dart';
import 'package:cg500_blueteeth_app/widgets/command/quick_command_button.dart';

void main() {
  late CommandRepository repository;

  setUp(() {
    repository = CommandRepository();
  });

  Widget buildTestWidget({
    ValueChanged<DeviceCommand>? onCommandSelected,
    VoidCallback? onOpenCommandMenu,
    String? executingCommand,
    bool isConnected = true,
    bool compact = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: QuickAccessBarWidget(
          repository: repository,
          onCommandSelected: onCommandSelected ?? (_) {},
          onOpenCommandMenu: onOpenCommandMenu ?? () {},
          executingCommand: executingCommand,
          isConnected: isConnected,
          compact: compact,
        ),
      ),
    );
  }

  group('QuickAccessBarWidget', () {
    group('rendering', () {
      testWidgets('displays quick access commands', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Should show multiple quick command buttons
        expect(find.byType(QuickCommandButton), findsWidgets);
      });

      testWidgets('displays all quick access commands from repository',
          (tester) async {
        await tester.pumpWidget(buildTestWidget());

        final quickCommands = repository.getQuickAccessCommands();
        expect(
          find.byType(QuickCommandButton),
          findsNWidgets(quickCommands.length),
        );
      });

      testWidgets('displays menu button', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Find the menu button by its text
        expect(find.text(AppStrings.more), findsOneWidget);
      });

      testWidgets('shows command icons', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Should show INFO icon (list_alt or info_outline)
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('renders in horizontal scrollable layout', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });

    group('command selection', () {
      testWidgets('calls onCommandSelected when quick command is tapped',
          (tester) async {
        DeviceCommand? selectedCommand;
        await tester.pumpWidget(buildTestWidget(
          onCommandSelected: (cmd) {
            selectedCommand = cmd;
          },
        ));

        // Tap the first quick command button
        await tester.tap(find.byType(QuickCommandButton).first);
        await tester.pump();

        expect(selectedCommand, isNotNull);
        expect(selectedCommand!.isQuickAccessible, true);
      });

      testWidgets('calls onOpenCommandMenu when menu button is tapped',
          (tester) async {
        bool menuOpened = false;
        await tester.pumpWidget(buildTestWidget(
          onOpenCommandMenu: () {
            menuOpened = true;
          },
        ));

        // Find and tap the menu button
        await tester.tap(find.text(AppStrings.more));
        await tester.pump();

        expect(menuOpened, true);
      });
    });

    group('loading state', () {
      testWidgets('shows loading indicator for executing command',
          (tester) async {
        final quickCommands = repository.getQuickAccessCommands();
        final firstCommand = quickCommands.first.command;

        await tester.pumpWidget(buildTestWidget(
          executingCommand: firstCommand,
        ));

        // Should show a CircularProgressIndicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('does not show loading for non-executing commands',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          executingCommand: r'$NONEXISTENT',
        ));

        // Should not show loading indicators
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });

    group('connection state', () {
      testWidgets('buttons are enabled when connected', (tester) async {
        bool commandSelected = false;
        await tester.pumpWidget(buildTestWidget(
          isConnected: true,
          onCommandSelected: (_) {
            commandSelected = true;
          },
        ));

        await tester.tap(find.byType(QuickCommandButton).first);
        await tester.pump();

        expect(commandSelected, true);
      });

      testWidgets('buttons are disabled when not connected', (tester) async {
        bool commandSelected = false;
        await tester.pumpWidget(buildTestWidget(
          isConnected: false,
          onCommandSelected: (_) {
            commandSelected = true;
          },
        ));

        await tester.tap(find.byType(QuickCommandButton).first);
        await tester.pump();

        expect(commandSelected, false);
      });

      testWidgets('menu button is disabled when not connected', (tester) async {
        bool menuOpened = false;
        await tester.pumpWidget(buildTestWidget(
          isConnected: false,
          onOpenCommandMenu: () {
            menuOpened = true;
          },
        ));

        await tester.tap(find.text(AppStrings.more));
        await tester.pump();

        expect(menuOpened, false);
      });
    });

    group('compact mode', () {
      testWidgets('uses smaller sizing in compact mode', (tester) async {
        await tester.pumpWidget(buildTestWidget(compact: true));

        // Should still render all elements
        expect(find.byType(QuickCommandButton), findsWidgets);
        expect(find.text(AppStrings.more), findsOneWidget);
      });
    });

    group('theming', () {
      testWidgets('renders correctly in light theme', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: QuickAccessBarWidget(
              repository: repository,
              onCommandSelected: (_) {},
              onOpenCommandMenu: () {},
            ),
          ),
        ));

        expect(find.byType(QuickAccessBarWidget), findsOneWidget);
      });

      testWidgets('renders correctly in dark theme', (tester) async {
        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: QuickAccessBarWidget(
              repository: repository,
              onCommandSelected: (_) {},
              onOpenCommandMenu: () {},
            ),
          ),
        ));

        expect(find.byType(QuickAccessBarWidget), findsOneWidget);
      });
    });
  });

  group('CompactQuickAccessBar', () {
    Widget buildCompactTestWidget({
      ValueChanged<DeviceCommand>? onCommandSelected,
      VoidCallback? onOpenCommandMenu,
      String? executingCommand,
      bool isConnected = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CompactQuickAccessBar(
            repository: repository,
            onCommandSelected: onCommandSelected ?? (_) {},
            onOpenCommandMenu: onOpenCommandMenu ?? () {},
            executingCommand: executingCommand,
            isConnected: isConnected,
          ),
        ),
      );
    }

    testWidgets('displays icon buttons only', (tester) async {
      await tester.pumpWidget(buildCompactTestWidget());

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('shows more_horiz icon for menu', (tester) async {
      await tester.pumpWidget(buildCompactTestWidget());

      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('calls onCommandSelected when icon is tapped', (tester) async {
      DeviceCommand? selectedCommand;
      await tester.pumpWidget(buildCompactTestWidget(
        onCommandSelected: (cmd) {
          selectedCommand = cmd;
        },
      ));

      // Tap an icon button (excluding the more_horiz menu button)
      final iconButtons = find.byType(IconButton);
      await tester.tap(iconButtons.first);
      await tester.pump();

      expect(selectedCommand, isNotNull);
    });

    testWidgets('calls onOpenCommandMenu when menu icon is tapped',
        (tester) async {
      bool menuOpened = false;
      await tester.pumpWidget(buildCompactTestWidget(
        onOpenCommandMenu: () {
          menuOpened = true;
        },
      ));

      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pump();

      expect(menuOpened, true);
    });

    testWidgets('shows loading state for executing command', (tester) async {
      final quickCommands = repository.getQuickAccessCommands();
      final firstCommand = quickCommands.first.command;

      await tester.pumpWidget(buildCompactTestWidget(
        executingCommand: firstCommand,
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables buttons when not connected', (tester) async {
      bool commandSelected = false;
      await tester.pumpWidget(buildCompactTestWidget(
        isConnected: false,
        onCommandSelected: (_) {
          commandSelected = true;
        },
      ));

      // Try tapping an icon button
      final iconButtons = find.byType(IconButton);
      await tester.tap(iconButtons.first);
      await tester.pump();

      expect(commandSelected, false);
    });
  });

  group('FloatingQuickAccessBar', () {
    Widget buildFloatingTestWidget({
      ValueChanged<DeviceCommand>? onCommandSelected,
      VoidCallback? onOpenCommandMenu,
      String? executingCommand,
      bool isConnected = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: FloatingQuickAccessBar(
              repository: repository,
              onCommandSelected: onCommandSelected ?? (_) {},
              onOpenCommandMenu: onOpenCommandMenu ?? () {},
              executingCommand: executingCommand,
              isConnected: isConnected,
            ),
          ),
        ),
      );
    }

    testWidgets('wraps QuickAccessBarWidget', (tester) async {
      await tester.pumpWidget(buildFloatingTestWidget());

      expect(find.byType(QuickAccessBarWidget), findsOneWidget);
    });

    testWidgets('has rounded corners', (tester) async {
      await tester.pumpWidget(buildFloatingTestWidget());

      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('has elevated shadow', (tester) async {
      await tester.pumpWidget(buildFloatingTestWidget());

      // Find the outer container with BoxDecoration
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('passes through command selection', (tester) async {
      DeviceCommand? selectedCommand;
      await tester.pumpWidget(buildFloatingTestWidget(
        onCommandSelected: (cmd) {
          selectedCommand = cmd;
        },
      ));

      await tester.tap(find.byType(QuickCommandButton).first);
      await tester.pump();

      expect(selectedCommand, isNotNull);
    });

    testWidgets('passes through menu open', (tester) async {
      bool menuOpened = false;
      await tester.pumpWidget(buildFloatingTestWidget(
        onOpenCommandMenu: () {
          menuOpened = true;
        },
      ));

      await tester.tap(find.text(AppStrings.more));
      await tester.pump();

      expect(menuOpened, true);
    });
  });

  group('integration with CommandRepository', () {
    testWidgets('displays correct number of quick access commands',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final quickCommands = repository.getQuickAccessCommands();
      expect(
        find.byType(QuickCommandButton),
        findsNWidgets(quickCommands.length),
      );
    });

    testWidgets('only shows safe commands without parameters', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      final quickCommands = repository.getQuickAccessCommands();
      for (final cmd in quickCommands) {
        expect(cmd.hasParameters, false);
        expect(cmd.dangerLevel, DangerLevel.safe);
      }
    });

    testWidgets('does not show dangerous commands', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // $STARTX is dangerous and should not appear
      expect(find.text('STARTX'), findsNothing);
    });

    testWidgets('does not show commands with parameters', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // $MAC requires parameters and should not appear
      expect(find.text('MAC'), findsNothing);
      // $ADDR requires parameters and should not appear
      expect(find.text('ADDR'), findsNothing);
    });
  });
}
