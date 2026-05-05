import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/core/service_locator.dart';

void main() {
  group('ServiceLocator', () {
    tearDown(() async {
      // Reset service locator after each test
      await resetServiceLocator();
    });

    group('initialization', () {
      test('isServiceLocatorInitialized returns false initially', () async {
        await resetServiceLocator();
        expect(isServiceLocatorInitialized, isFalse);
      });

      test('setupServiceLocator sets isInitialized to true', () async {
        await resetServiceLocator();
        await setupServiceLocator();
        expect(isServiceLocatorInitialized, isTrue);
      });

      test('setupServiceLocator is idempotent', () async {
        await resetServiceLocator();
        await setupServiceLocator();
        await setupServiceLocator(); // Should not throw
        expect(isServiceLocatorInitialized, isTrue);
      });

      test('resetServiceLocator resets initialization state', () async {
        await setupServiceLocator();
        expect(isServiceLocatorInitialized, isTrue);
        await resetServiceLocator();
        expect(isServiceLocatorInitialized, isFalse);
      });

      test('resetServiceLocator is safe to call multiple times', () async {
        await resetServiceLocator();
        await resetServiceLocator();
        await resetServiceLocator();
        expect(isServiceLocatorInitialized, isFalse);
      });
    });

    group('getIt access', () {
      test('getIt is the singleton instance', () {
        expect(getIt, isNotNull);
        expect(getIt, equals(getIt)); // Same instance
      });
    });
  });
}
