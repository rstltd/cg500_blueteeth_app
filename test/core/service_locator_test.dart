import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/core/service_locator.dart';
import 'package:cg500_blueteeth_app/services/network_service.dart';
import 'package:cg500_blueteeth_app/services/notification_service.dart';
import 'package:cg500_blueteeth_app/services/ble_service.dart';
import 'package:cg500_blueteeth_app/services/update_service.dart';
import 'package:cg500_blueteeth_app/services/permission_service.dart';
import 'package:cg500_blueteeth_app/controllers/ble_controller_interface.dart';

// Mock implementations for testing
import '../mocks/mock_services.dart';

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

    group('test service locator setup', () {
      test('setupTestServiceLocator with mock network service', () async {
        await resetServiceLocator();
        final mockNetwork = MockNetworkService();

        setupTestServiceLocator(
          mockNetworkService: mockNetwork,
        );

        expect(isServiceLocatorInitialized, isTrue);
        expect(getIt<NetworkService>(), equals(mockNetwork));
      });

      test('setupTestServiceLocator with mock notification service', () async {
        await resetServiceLocator();
        final mockNotification = MockNotificationService();

        setupTestServiceLocator(
          mockNotificationService: mockNotification,
        );

        expect(isServiceLocatorInitialized, isTrue);
        expect(getIt<NotificationService>(), equals(mockNotification));
      });

      test('setupTestServiceLocator with mock permission service', () async {
        await resetServiceLocator();
        final mockPermission = MockPermissionService();

        setupTestServiceLocator(
          mockPermissionService: mockPermission,
        );

        expect(isServiceLocatorInitialized, isTrue);
        expect(getIt<PermissionService>(), equals(mockPermission));
      });

      test('setupTestServiceLocator with mock BLE service', () async {
        await resetServiceLocator();
        final mockBle = MockBleService();

        setupTestServiceLocator(
          mockBleService: mockBle,
        );

        expect(isServiceLocatorInitialized, isTrue);
        expect(getIt<BleService>(), equals(mockBle));
      });

      test('setupTestServiceLocator with mock update service', () async {
        await resetServiceLocator();
        final mockUpdate = MockUpdateService();

        setupTestServiceLocator(
          mockUpdateService: mockUpdate,
        );

        expect(isServiceLocatorInitialized, isTrue);
        expect(getIt<UpdateService>(), equals(mockUpdate));
      });

      test('setupTestServiceLocator with mock BLE controller', () async {
        await resetServiceLocator();
        final mockController = MockBleController();

        setupTestServiceLocator(
          mockBleController: mockController,
        );

        expect(isServiceLocatorInitialized, isTrue);
        expect(getIt<BleControllerInterface>(), equals(mockController));
      });

      test('setupTestServiceLocator with all mocks', () async {
        await resetServiceLocator();
        final mockNetwork = MockNetworkService();
        final mockNotification = MockNotificationService();
        final mockPermission = MockPermissionService();
        final mockBle = MockBleService();
        final mockUpdate = MockUpdateService();
        final mockController = MockBleController();

        setupTestServiceLocator(
          mockNetworkService: mockNetwork,
          mockNotificationService: mockNotification,
          mockPermissionService: mockPermission,
          mockBleService: mockBle,
          mockUpdateService: mockUpdate,
          mockBleController: mockController,
        );

        expect(isServiceLocatorInitialized, isTrue);
        expect(getIt<NetworkService>(), equals(mockNetwork));
        expect(getIt<NotificationService>(), equals(mockNotification));
        expect(getIt<PermissionService>(), equals(mockPermission));
        expect(getIt<BleService>(), equals(mockBle));
        expect(getIt<UpdateService>(), equals(mockUpdate));
        expect(getIt<BleControllerInterface>(), equals(mockController));
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
