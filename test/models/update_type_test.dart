import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/update_type.dart';

void main() {
  group('UpdateType', () {
    test('should have all expected values', () {
      expect(UpdateType.values.length, 4);
      expect(UpdateType.values, contains(UpdateType.optional));
      expect(UpdateType.values, contains(UpdateType.recommended));
      expect(UpdateType.values, contains(UpdateType.critical));
      expect(UpdateType.values, contains(UpdateType.forced));
    });

    test('optional should have correct name', () {
      expect(UpdateType.optional.name, 'optional');
    });

    test('recommended should have correct name', () {
      expect(UpdateType.recommended.name, 'recommended');
    });

    test('critical should have correct name', () {
      expect(UpdateType.critical.name, 'critical');
    });

    test('forced should have correct name', () {
      expect(UpdateType.forced.name, 'forced');
    });

    test('should be able to find by name', () {
      expect(
        UpdateType.values.firstWhere((t) => t.name == 'optional'),
        UpdateType.optional,
      );
      expect(
        UpdateType.values.firstWhere((t) => t.name == 'recommended'),
        UpdateType.recommended,
      );
      expect(
        UpdateType.values.firstWhere((t) => t.name == 'critical'),
        UpdateType.critical,
      );
      expect(
        UpdateType.values.firstWhere((t) => t.name == 'forced'),
        UpdateType.forced,
      );
    });

    test('should have correct index order', () {
      expect(UpdateType.optional.index, 0);
      expect(UpdateType.recommended.index, 1);
      expect(UpdateType.critical.index, 2);
      expect(UpdateType.forced.index, 3);
    });
  });
}
