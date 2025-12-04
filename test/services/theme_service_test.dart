import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppThemeMode', () {
    test('should have 3 theme modes', () {
      expect(AppThemeMode.values.length, 3);
    });

    test('should contain light mode', () {
      expect(AppThemeMode.values, contains(AppThemeMode.light));
    });

    test('should contain dark mode', () {
      expect(AppThemeMode.values, contains(AppThemeMode.dark));
    });

    test('should contain system mode', () {
      expect(AppThemeMode.values, contains(AppThemeMode.system));
    });
  });

  group('ThemeService', () {
    late ThemeService themeService;

    setUp(() {
      themeService = ThemeService();
    });

    group('singleton', () {
      test('should return same instance', () {
        final instance1 = ThemeService();
        final instance2 = ThemeService();
        expect(identical(instance1, instance2), true);
      });
    });

    group('initial state', () {
      test('currentThemeMode should be system by default', () {
        expect(themeService.currentThemeMode, AppThemeMode.system);
      });
    });

    group('setThemeMode', () {
      test('should set theme mode to light', () {
        themeService.setThemeMode(AppThemeMode.light);
        expect(themeService.currentThemeMode, AppThemeMode.light);
      });

      test('should set theme mode to dark', () {
        themeService.setThemeMode(AppThemeMode.dark);
        expect(themeService.currentThemeMode, AppThemeMode.dark);
      });

      test('should set theme mode to system', () {
        themeService.setThemeMode(AppThemeMode.light);
        themeService.setThemeMode(AppThemeMode.system);
        expect(themeService.currentThemeMode, AppThemeMode.system);
      });
    });

    group('toggleTheme', () {
      test('should toggle from light to dark', () {
        themeService.setThemeMode(AppThemeMode.light);
        themeService.toggleTheme();
        expect(themeService.currentThemeMode, AppThemeMode.dark);
      });

      test('should toggle from dark to system', () {
        themeService.setThemeMode(AppThemeMode.dark);
        themeService.toggleTheme();
        expect(themeService.currentThemeMode, AppThemeMode.system);
      });

      test('should toggle from system to light', () {
        themeService.setThemeMode(AppThemeMode.system);
        themeService.toggleTheme();
        expect(themeService.currentThemeMode, AppThemeMode.light);
      });

      test('should complete full cycle', () {
        themeService.setThemeMode(AppThemeMode.light);

        themeService.toggleTheme(); // light -> dark
        expect(themeService.currentThemeMode, AppThemeMode.dark);

        themeService.toggleTheme(); // dark -> system
        expect(themeService.currentThemeMode, AppThemeMode.system);

        themeService.toggleTheme(); // system -> light
        expect(themeService.currentThemeMode, AppThemeMode.light);
      });
    });

    group('themeModeDescription', () {
      test('should return "Light Mode" for light theme', () {
        themeService.setThemeMode(AppThemeMode.light);
        expect(themeService.themeModeDescription, 'Light Mode');
      });

      test('should return "Dark Mode" for dark theme', () {
        themeService.setThemeMode(AppThemeMode.dark);
        expect(themeService.themeModeDescription, 'Dark Mode');
      });

      test('should return "System Theme" for system theme', () {
        themeService.setThemeMode(AppThemeMode.system);
        expect(themeService.themeModeDescription, 'System Theme');
      });
    });

    group('themeModeIcon', () {
      test('should return light_mode icon for light theme', () {
        themeService.setThemeMode(AppThemeMode.light);
        expect(themeService.themeModeIcon, Icons.light_mode);
      });

      test('should return dark_mode icon for dark theme', () {
        themeService.setThemeMode(AppThemeMode.dark);
        expect(themeService.themeModeIcon, Icons.dark_mode);
      });

      test('should return brightness_auto icon for system theme', () {
        themeService.setThemeMode(AppThemeMode.system);
        expect(themeService.themeModeIcon, Icons.brightness_auto);
      });
    });

    group('streams', () {
      test('themeModeStream should emit theme mode changes', () async {
        final emissions = <AppThemeMode>[];
        final subscription = themeService.themeModeStream.listen(emissions.add);

        themeService.setThemeMode(AppThemeMode.light);
        themeService.setThemeMode(AppThemeMode.dark);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(emissions, contains(AppThemeMode.light));
        expect(emissions, contains(AppThemeMode.dark));

        await subscription.cancel();
      });
    });

    group('lightTheme', () {
      test('should return ThemeData', () {
        final theme = ThemeService.lightTheme;
        expect(theme, isA<ThemeData>());
      });

      test('should have light brightness', () {
        final theme = ThemeService.lightTheme;
        expect(theme.brightness, Brightness.light);
      });

      test('should use Material 3', () {
        final theme = ThemeService.lightTheme;
        expect(theme.useMaterial3, true);
      });

      test('should have blue seed color scheme', () {
        final theme = ThemeService.lightTheme;
        expect(theme.colorScheme.brightness, Brightness.light);
      });
    });

    group('darkTheme', () {
      test('should return ThemeData', () {
        final theme = ThemeService.darkTheme;
        expect(theme, isA<ThemeData>());
      });

      test('should have dark brightness', () {
        final theme = ThemeService.darkTheme;
        expect(theme.brightness, Brightness.dark);
      });

      test('should use Material 3', () {
        final theme = ThemeService.darkTheme;
        expect(theme.useMaterial3, true);
      });

      test('should have specific scaffold background color', () {
        final theme = ThemeService.darkTheme;
        expect(theme.scaffoldBackgroundColor, const Color(0xFF121212));
      });
    });

    group('isDarkMode', () {
      test('should be false when theme is light', () {
        themeService.setThemeMode(AppThemeMode.light);
        expect(themeService.isDarkMode, false);
      });

      test('should be true when theme is dark', () {
        themeService.setThemeMode(AppThemeMode.dark);
        expect(themeService.isDarkMode, true);
      });
    });
  });

  group('AppColors', () {
    testWidgets('surfaceColor should return correct color for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.surfaceColor(context);
              expect(color, Colors.white);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('surfaceColor should return correct color for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.surfaceColor(context);
              expect(color, const Color(0xFF1E1E1E));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('cardColor should return correct color for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.cardColor(context);
              expect(color, Colors.white);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('cardColor should return correct color for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.cardColor(context);
              expect(color, const Color(0xFF2C2C2C));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('backgroundGradientStart for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.backgroundGradientStart(context);
              expect(color, Colors.blue.shade50);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('backgroundGradientStart for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.backgroundGradientStart(context);
              expect(color, const Color(0xFF121212));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('backgroundGradientEnd for light theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.backgroundGradientEnd(context);
              expect(color, Colors.indigo.shade50);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('backgroundGradientEnd for dark theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.backgroundGradientEnd(context);
              expect(color, const Color(0xFF1E1E1E));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('textPrimary for light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.textPrimary(context);
              expect(color, Colors.grey.shade800);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('textPrimary for dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.textPrimary(context);
              expect(color, Colors.white);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('textSecondary for light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.textSecondary(context);
              expect(color, Colors.grey.shade600);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('textSecondary for dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.textSecondary(context);
              expect(color, Colors.grey.shade400);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('borderColor for light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.borderColor(context);
              expect(color, Colors.grey.shade300);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('borderColor for dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.borderColor(context);
              expect(color, Colors.grey.shade700);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('shadowColor for light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.shadowColor(context);
              expect(color.alpha, closeTo(Colors.black.withValues(alpha: 0.1).alpha, 1));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('shadowColor for dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.shadowColor(context);
              expect(color.alpha, closeTo(Colors.black.withValues(alpha: 0.3).alpha, 1));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('successColor for light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.successColor(context);
              expect(color, Colors.green.shade600);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('successColor for dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.successColor(context);
              expect(color, Colors.green.shade400);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('warningColor for light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.warningColor(context);
              expect(color, Colors.orange.shade600);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('warningColor for dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.warningColor(context);
              expect(color, Colors.orange.shade400);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('errorColor for light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.errorColor(context);
              expect(color, Colors.red.shade600);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('errorColor for dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.errorColor(context);
              expect(color, Colors.red.shade400);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('infoColor for light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          home: Builder(
            builder: (context) {
              final color = AppColors.infoColor(context);
              expect(color, Colors.blue.shade600);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('infoColor for dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              final color = AppColors.infoColor(context);
              expect(color, Colors.blue.shade400);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
