import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/command/command_category.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';

void main() {
  group('CommandCategory', () {
    test('should have 5 categories', () {
      expect(CommandCategory.values.length, 5);
    });

    test('should contain expected categories', () {
      expect(CommandCategory.values, contains(CommandCategory.query));
      expect(CommandCategory.values, contains(CommandCategory.config));
      expect(CommandCategory.values, contains(CommandCategory.control));
      expect(CommandCategory.values, contains(CommandCategory.debug));
      expect(CommandCategory.values, contains(CommandCategory.custom));
    });
  });

  group('CommandCategoryExtension', () {
    group('displayName', () {
      test('query should return category query name', () {
        expect(CommandCategory.query.displayName, AppStrings.categoryQuery);
      });

      test('config should return category config name', () {
        expect(CommandCategory.config.displayName, AppStrings.categoryConfig);
      });

      test('control should return category control name', () {
        expect(CommandCategory.control.displayName, AppStrings.categoryControl);
      });

      test('debug should return category debug name', () {
        expect(CommandCategory.debug.displayName, AppStrings.categoryDebug);
      });
    });

    group('iconName', () {
      test('all categories should have icon names', () {
        for (final category in CommandCategory.values) {
          expect(category.iconName, isNotEmpty);
        }
      });
    });

    group('description', () {
      test('all categories should have descriptions', () {
        for (final category in CommandCategory.values) {
          expect(category.description, isNotEmpty);
        }
      });
    });

    group('sortOrder', () {
      test('query should be first (0)', () {
        expect(CommandCategory.query.sortOrder, 0);
      });

      test('config should be second (1)', () {
        expect(CommandCategory.config.sortOrder, 1);
      });

      test('control should be third (2)', () {
        expect(CommandCategory.control.sortOrder, 2);
      });

      test('debug should be fourth (3)', () {
        expect(CommandCategory.debug.sortOrder, 3);
      });

      test('custom should be last (4)', () {
        expect(CommandCategory.custom.sortOrder, 4);
      });

      test('sortOrder should produce correct ordering', () {
        final sorted = CommandCategory.values.toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        expect(sorted, [
          CommandCategory.query,
          CommandCategory.config,
          CommandCategory.control,
          CommandCategory.debug,
          CommandCategory.custom,
        ]);
      });
    });
  });
}
