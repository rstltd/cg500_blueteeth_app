import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/command/danger_level.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

void main() {
  group('DangerLevel', () {
    test('should have 3 levels', () {
      expect(DangerLevel.values.length, 3);
    });

    test('should contain expected levels', () {
      expect(DangerLevel.values, contains(DangerLevel.safe));
      expect(DangerLevel.values, contains(DangerLevel.warning));
      expect(DangerLevel.values, contains(DangerLevel.dangerous));
    });
  });

  group('DangerLevelExtension', () {
    group('requiresConfirmation', () {
      test('safe should not require confirmation', () {
        expect(DangerLevel.safe.requiresConfirmation, false);
      });

      test('warning should require confirmation', () {
        expect(DangerLevel.warning.requiresConfirmation, true);
      });

      test('dangerous should require confirmation', () {
        expect(DangerLevel.dangerous.requiresConfirmation, true);
      });
    });

    group('displayName', () {
      test('safe should return safe display name', () {
        expect(DangerLevel.safe.displayName, AppStrings.dangerLevelSafe);
      });

      test('warning should return warning display name', () {
        expect(DangerLevel.warning.displayName, AppStrings.dangerLevelWarning);
      });

      test('dangerous should return dangerous display name', () {
        expect(DangerLevel.dangerous.displayName, AppStrings.dangerLevelDangerous);
      });
    });

    group('color', () {
      test('safe should be green', () {
        expect(DangerLevel.safe.color, Colors.green);
      });

      test('warning should be orange', () {
        expect(DangerLevel.warning.color, Colors.orange);
      });

      test('dangerous should be red', () {
        expect(DangerLevel.dangerous.color, Colors.red);
      });
    });

    group('icon', () {
      test('all levels should have icons', () {
        for (final level in DangerLevel.values) {
          expect(level.icon, isA<IconData>());
        }
      });

      test('safe should have check_circle_outline icon', () {
        expect(DangerLevel.safe.icon, Icons.check_circle_outline);
      });

      test('warning should have warning_amber_outlined icon', () {
        expect(DangerLevel.warning.icon, Icons.warning_amber_outlined);
      });

      test('dangerous should have dangerous_outlined icon', () {
        expect(DangerLevel.dangerous.icon, Icons.dangerous_outlined);
      });
    });

    group('confirmationTitle', () {
      test('all levels should have confirmation titles', () {
        for (final level in DangerLevel.values) {
          expect(level.confirmationTitle, isNotEmpty);
        }
      });
    });

    group('confirmButtonText', () {
      test('all levels should have confirm button text', () {
        for (final level in DangerLevel.values) {
          expect(level.confirmButtonText, isNotEmpty);
        }
      });

      test('dangerous should have stronger confirmation text', () {
        expect(
          DangerLevel.dangerous.confirmButtonText.length,
          greaterThan(DangerLevel.safe.confirmButtonText.length),
        );
      });
    });
  });
}
