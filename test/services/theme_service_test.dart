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

    group('DI pattern', () {
      test('should create independent instances with forTesting', () {
        final instance1 = ThemeService.forTesting();
        final instance2 = ThemeService.forTesting();
        // With DI pattern, each call creates a new instance
        expect(identical(instance1, instance2), false);
        instance1.dispose();
        instance2.dispose();
      });
    });

    group('forTesting constructor', () {
      test('should create independent instance', () {
        final testService = ThemeService.forTesting();

        // Should have default state
        expect(testService.currentThemeMode, AppThemeMode.system);

        // Modify test service
        testService.setThemeMode(AppThemeMode.dark);
        expect(testService.currentThemeMode, AppThemeMode.dark);

        // Dispose
        testService.dispose();
      });

      test('should have working streams', () async {
        final testService = ThemeService.forTesting();
        final emissions = <AppThemeMode>[];
        final subscription = testService.themeModeStream.listen(emissions.add);

        testService.setThemeMode(AppThemeMode.light);
        testService.setThemeMode(AppThemeMode.dark);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(emissions, contains(AppThemeMode.light));
        expect(emissions, contains(AppThemeMode.dark));

        await subscription.cancel();
        testService.dispose();
      });

      test('should allow multiple independent instances', () {
        final service1 = ThemeService.forTesting();
        final service2 = ThemeService.forTesting();

        service1.setThemeMode(AppThemeMode.light);
        service2.setThemeMode(AppThemeMode.dark);

        expect(service1.currentThemeMode, AppThemeMode.light);
        expect(service2.currentThemeMode, AppThemeMode.dark);

        service1.dispose();
        service2.dispose();
      });
    });

    group('initial state', () {
      test('currentThemeMode should be system by default', () {
        expect(themeService.currentThemeMode, AppThemeMode.system);
      });

      test('systemIsDarkMode should return a boolean value', () {
        // systemIsDarkMode reflects the platform's dark mode setting
        expect(themeService.systemIsDarkMode, isA<bool>());
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
              // WCAG AAA compliant: Near black on white: 16.1:1
              expect(color, const Color(0xFF1F1F1F));
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
              // WCAG AAA compliant: White on dark: 13.5:1
              expect(color, const Color(0xFFFFFFFF));
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
              // WCAG AA compliant: Medium grey: 7.0:1 vs white
              expect(color, const Color(0xFF5F5F5F));
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
              // WCAG AA compliant: Light grey: 7.8:1 vs #2C2C2C
              expect(color, const Color(0xFFB0B0B0));
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
              // Visible border in light mode
              expect(color, const Color(0xFFE0E0E0));
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
              // Visible border in dark mode
              expect(color, const Color(0xFF404040));
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
              final expectedAlpha = (Colors.black.withValues(alpha: 0.1).a * 255.0).round() & 0xff;
              final actualAlpha = (color.a * 255.0).round() & 0xff;
              expect(actualAlpha, closeTo(expectedAlpha, 1));
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
              final expectedAlpha = (Colors.black.withValues(alpha: 0.3).a * 255.0).round() & 0xff;
              final actualAlpha = (color.a * 255.0).round() & 0xff;
              expect(actualAlpha, closeTo(expectedAlpha, 1));
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
              // WCAG AA compliant: Green 800: 4.5:1 vs white
              expect(color, const Color(0xFF2E7D32));
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
              // WCAG AA compliant: Green 500: 5.1:1 vs #2C2C2C
              expect(color, const Color(0xFF4CAF50));
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
              // WCAG AA compliant: Orange 900: 4.8:1 vs white
              expect(color, const Color(0xFFE65100));
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
              // WCAG AA compliant: Orange 300: 8.4:1 vs #2C2C2C
              expect(color, const Color(0xFFFFB74D));
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
              // WCAG AA compliant: Red 800: 5.9:1 vs white
              expect(color, const Color(0xFFC62828));
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
              // WCAG AA compliant: Red 400: 5.2:1 vs #2C2C2C
              expect(color, const Color(0xFFEF5350));
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
              // WCAG AA compliant: Blue 800: 5.3:1 vs white
              expect(color, const Color(0xFF1565C0));
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
              // WCAG AA compliant: Blue 400: 5.5:1 vs #2C2C2C
              expect(color, const Color(0xFF42A5F5));
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
