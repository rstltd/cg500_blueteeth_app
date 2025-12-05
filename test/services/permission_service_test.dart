import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cg500_blueteeth_app/services/permission_service.dart';

void main() {
  group('PermissionService', () {
    late PermissionService service;

    setUp(() {
      service = PermissionService();
    });

    group('DI pattern', () {
      test('should create independent instances with constructor', () {
        final instance1 = PermissionService();
        final instance2 = PermissionService();

        // With DI pattern, each call creates a new instance
        expect(identical(instance1, instance2), isFalse);
      });

      test('constructor instances are independent', () {
        final testService = PermissionService();
        // Each constructor call creates a new instance
        expect(identical(service, testService), isFalse);
      });
    });

    group('getPermissionStatusDescription', () {
      test('should return correct description for granted status', () {
        final description = service.getPermissionStatusDescription(
          PermissionStatus.granted,
        );

        expect(description, 'Permission granted');
      });

      test('should return correct description for denied status', () {
        final description = service.getPermissionStatusDescription(
          PermissionStatus.denied,
        );

        expect(description, 'Permission denied');
      });

      test('should return correct description for restricted status', () {
        final description = service.getPermissionStatusDescription(
          PermissionStatus.restricted,
        );

        expect(description, 'Permission restricted');
      });

      test('should return correct description for limited status', () {
        final description = service.getPermissionStatusDescription(
          PermissionStatus.limited,
        );

        expect(description, 'Permission limited');
      });

      test('should return correct description for permanentlyDenied status', () {
        final description = service.getPermissionStatusDescription(
          PermissionStatus.permanentlyDenied,
        );

        expect(description, 'Permission permanently denied - please enable in settings');
      });

      test('should return correct description for provisional status', () {
        final description = service.getPermissionStatusDescription(
          PermissionStatus.provisional,
        );

        expect(description, 'Permission provisional');
      });

      test('should handle all PermissionStatus enum values', () {
        // Ensure all enum values are handled without throwing
        for (final status in PermissionStatus.values) {
          expect(
            () => service.getPermissionStatusDescription(status),
            returnsNormally,
            reason: 'Should handle $status without throwing',
          );
        }
      });

      test('all status descriptions should be non-empty strings', () {
        for (final status in PermissionStatus.values) {
          final description = service.getPermissionStatusDescription(status);
          expect(description.isNotEmpty, isTrue,
              reason: 'Description for $status should not be empty');
        }
      });

      test('permanentlyDenied should contain settings guidance', () {
        final description = service.getPermissionStatusDescription(
          PermissionStatus.permanentlyDenied,
        );

        expect(description.toLowerCase(), contains('settings'));
      });

      test('granted description should indicate success', () {
        final description = service.getPermissionStatusDescription(
          PermissionStatus.granted,
        );

        expect(description.toLowerCase(), contains('granted'));
      });

      test('denied description should indicate denial', () {
        final description = service.getPermissionStatusDescription(
          PermissionStatus.denied,
        );

        expect(description.toLowerCase(), contains('denied'));
      });
    });

    group('method existence', () {
      test('should have requestBluetoothPermissions method', () {
        expect(service.requestBluetoothPermissions, isA<Function>());
      });

      test('should have hasBluetoothPermissions method', () {
        expect(service.hasBluetoothPermissions, isA<Function>());
      });

      test('should have getBluetoothStatus method', () {
        expect(service.getBluetoothStatus, isA<Function>());
      });

      test('should have getLocationStatus method', () {
        expect(service.getLocationStatus, isA<Function>());
      });

      test('should have shouldShowBluetoothRationale method', () {
        expect(service.shouldShowBluetoothRationale, isA<Function>());
      });

      test('should have shouldShowLocationRationale method', () {
        expect(service.shouldShowLocationRationale, isA<Function>());
      });

      test('should have openAppSettings method', () {
        expect(service.openAppSettings, isA<Function>());
      });

      test('should have getPermissionStatusDescription method', () {
        expect(service.getPermissionStatusDescription, isA<Function>());
      });
    });
  });
}
