import 'package:get_it/get_it.dart';

// Interface imports
import 'interfaces/network_service_interface.dart';
import 'interfaces/notification_service_interface.dart';
import 'interfaces/permission_service_interface.dart';
import 'interfaces/ble_service_interface.dart';
import 'interfaces/update_service_interface.dart';
// Note: ErrorHandlingServiceInterface is imported via error_handling_service.dart's re-export
import '../controllers/ble_controller_interface.dart';

// Implementation imports
import '../services/network_service.dart';
import '../services/smart_notification_service.dart';
import '../services/permission_service.dart';
import '../services/ble_service.dart';
import '../services/update_service.dart';
import '../services/theme_service.dart';
import '../services/error_handling_service.dart';
import '../controllers/simple_ble_controller.dart';
import '../controllers/app_update_manager.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Flag to track if service locator has been initialized
bool _isInitialized = false;

/// Check if service locator is initialized
bool get isServiceLocatorInitialized => _isInitialized;

/// Initialize all services for production use.
///
/// This should be called once at app startup before any services are used.
/// The initialization order is important - base services must be registered
/// before services that depend on them.
Future<void> setupServiceLocator() async {
  if (_isInitialized) {
    return;
  }

  // ============================================
  // Base services (no dependencies)
  // ============================================

  // NetworkService - network connectivity monitoring
  getIt.registerLazySingleton<NetworkServiceInterface>(
    () => NetworkService.withDependencies(),
  );

  // SmartNotificationService - notification filtering and management
  getIt.registerLazySingleton<NotificationServiceInterface>(
    () => SmartNotificationService.withDependencies(),
  );

  // PermissionService - Bluetooth and location permissions
  getIt.registerLazySingleton<PermissionServiceInterface>(
    () => PermissionService.withDependencies(),
  );

  // ThemeService - app theme management (light/dark mode)
  getIt.registerLazySingleton<ThemeService>(
    () => ThemeService(),
  );

  // ============================================
  // Services with dependencies
  // ============================================

  // ErrorHandlingService - centralized error handling
  getIt.registerLazySingleton<ErrorHandlingServiceInterface>(
    () => ErrorHandlingService(
      notificationService: getIt<NotificationServiceInterface>(),
    ),
  );

  // BleService - Bluetooth Low Energy operations
  getIt.registerLazySingleton<BleServiceInterface>(
    () => BleService.withDependencies(
      permissionService: getIt<PermissionServiceInterface>(),
      notificationService: getIt<NotificationServiceInterface>(),
    ),
  );

  // UpdateService - app update management
  getIt.registerLazySingleton<UpdateServiceInterface>(
    () => UpdateService.withDependencies(
      networkService: getIt<NetworkServiceInterface>(),
      notificationService: getIt<NotificationServiceInterface>(),
    ),
  );

  // ============================================
  // Controllers
  // ============================================

  // SimpleBleController - BLE operations coordinator
  getIt.registerLazySingleton<BleControllerInterface>(
    () => SimpleBleController.withDependencies(
      bleService: getIt<BleServiceInterface>(),
      notificationService: getIt<NotificationServiceInterface>(),
    ),
  );

  // AppUpdateManager - coordinated update operations
  getIt.registerLazySingleton<AppUpdateManager>(
    () => AppUpdateManager.withDependencies(
      updateService: getIt<UpdateServiceInterface>(),
      networkService: getIt<NetworkServiceInterface>(),
      notificationService: getIt<NotificationServiceInterface>(),
    ),
  );

  _isInitialized = true;
}

/// Reset service locator - primarily used for testing.
///
/// This will dispose all registered services and allow re-registration.
Future<void> resetServiceLocator() async {
  if (_isInitialized) {
    await getIt.reset();
    _isInitialized = false;
  }
}

/// Setup service locator for testing with mock services.
///
/// Usage in tests:
/// ```dart
/// setUp(() async {
///   await resetServiceLocator();
///   setupTestServiceLocator(
///     mockNetworkService: MockNetworkService(),
///     mockBleService: MockBleService(),
///   );
/// });
/// ```
void setupTestServiceLocator({
  NetworkServiceInterface? mockNetworkService,
  NotificationServiceInterface? mockNotificationService,
  PermissionServiceInterface? mockPermissionService,
  BleServiceInterface? mockBleService,
  UpdateServiceInterface? mockUpdateService,
  BleControllerInterface? mockBleController,
  ErrorHandlingServiceInterface? mockErrorHandlingService,
  AppUpdateManager? mockAppUpdateManager,
}) {
  // Register mock services if provided, otherwise use defaults
  if (mockNetworkService != null) {
    getIt.registerSingleton<NetworkServiceInterface>(mockNetworkService);
  }

  if (mockNotificationService != null) {
    getIt.registerSingleton<NotificationServiceInterface>(mockNotificationService);
  }

  if (mockPermissionService != null) {
    getIt.registerSingleton<PermissionServiceInterface>(mockPermissionService);
  }

  if (mockBleService != null) {
    getIt.registerSingleton<BleServiceInterface>(mockBleService);
  }

  if (mockUpdateService != null) {
    getIt.registerSingleton<UpdateServiceInterface>(mockUpdateService);
  }

  if (mockBleController != null) {
    getIt.registerSingleton<BleControllerInterface>(mockBleController);
  }

  if (mockErrorHandlingService != null) {
    getIt.registerSingleton<ErrorHandlingServiceInterface>(mockErrorHandlingService);
  }

  if (mockAppUpdateManager != null) {
    getIt.registerSingleton<AppUpdateManager>(mockAppUpdateManager);
  }

  _isInitialized = true;
}
