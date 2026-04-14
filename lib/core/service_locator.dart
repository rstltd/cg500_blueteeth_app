import 'package:get_it/get_it.dart';

// Interface imports
import 'interfaces/command_repository_interface.dart';
import '../controllers/ble_controller_interface.dart';

// Implementation imports
import '../services/network_service.dart';
import '../services/notification_service.dart';
import '../services/smart_notification_service.dart';
import '../services/permission_service.dart';
import '../services/ble_service.dart';
import '../services/update_service.dart';
import '../services/update_checker.dart';
import '../services/download_manager.dart';
import '../services/install_manager.dart';
import '../services/theme_service.dart';
import '../services/error_handling_service.dart';
import '../services/command_parameter_storage_service.dart';
import '../services/role_service.dart';
import '../repositories/command_repository.dart';
import '../repositories/role_aware_command_repository.dart';
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
  getIt.registerLazySingleton<NetworkService>(
    () => NetworkService.withDependencies(),
  );

  // SmartNotificationService - notification filtering and management
  getIt.registerLazySingleton<NotificationService>(
    () => SmartNotificationService.withDependencies(),
  );

  // PermissionService - Bluetooth and location permissions
  getIt.registerLazySingleton<PermissionService>(
    () => PermissionService.withDependencies(),
  );

  // ThemeService - app theme management (light/dark mode)
  getIt.registerLazySingleton<ThemeService>(
    () => ThemeService(),
  );

  // CommandParameterStorageService - command parameter persistence
  getIt.registerLazySingleton<CommandParameterStorageService>(
    () => CommandParameterStorageService(),
  );

  // RoleService - tracks current user role and password hash
  getIt.registerLazySingleton<RoleService>(
    () => RoleService(),
  );

  // CommandRepository - device command definitions, wrapped with role-aware
  // filtering. Field operators (normal mode) only see the whitelist.
  getIt.registerLazySingleton<CommandRepositoryInterface>(
    () => RoleAwareCommandRepository(
      inner: CommandRepository(),
      roleService: getIt<RoleService>(),
    ),
  );

  // ============================================
  // Services with dependencies
  // ============================================

  // ErrorHandlingService - centralized error handling
  getIt.registerLazySingleton<ErrorHandlingService>(
    () => ErrorHandlingService(
      notificationService: getIt<NotificationService>(),
    ),
  );

  // BleService - Bluetooth Low Energy operations
  getIt.registerLazySingleton<BleService>(
    () => BleService.withDependencies(
      permissionService: getIt<PermissionService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );

  // ============================================
  // Update system services
  // ============================================

  // UpdateChecker - version checking and update detection
  getIt.registerLazySingleton<UpdateChecker>(
    () => UpdateChecker.withDependencies(),
  );

  // DownloadManager - APK download with progress tracking
  getIt.registerLazySingleton<DownloadManager>(
    () => DownloadManager.withDependencies(
      notificationService: getIt<NotificationService>(),
      networkService: getIt<NetworkService>(),
    ),
  );

  // InstallManager - APK installation on Android
  getIt.registerLazySingleton<InstallManager>(
    () => InstallManager.withDependencies(
      notificationService: getIt<NotificationService>(),
    ),
  );

  // UpdateService - coordinated update operations (facade)
  getIt.registerLazySingleton<UpdateService>(
    () => UpdateService.withDependencies(
      networkService: getIt<NetworkService>(),
      notificationService: getIt<NotificationService>(),
      updateChecker: getIt<UpdateChecker>(),
      downloadManager: getIt<DownloadManager>(),
      installManager: getIt<InstallManager>(),
    ),
  );

  // ============================================
  // Controllers
  // ============================================

  // SimpleBleController - BLE operations coordinator
  getIt.registerLazySingleton<BleControllerInterface>(
    () => SimpleBleController.withDependencies(
      bleService: getIt<BleService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );

  // AppUpdateManager - coordinated update operations
  getIt.registerLazySingleton<AppUpdateManager>(
    () => AppUpdateManager.withDependencies(
      updateService: getIt<UpdateService>(),
      networkService: getIt<NetworkService>(),
      notificationService: getIt<NotificationService>(),
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
  NetworkService? mockNetworkService,
  NotificationService? mockNotificationService,
  PermissionService? mockPermissionService,
  BleService? mockBleService,
  UpdateService? mockUpdateService,
  UpdateChecker? mockUpdateChecker,
  DownloadManager? mockDownloadManager,
  InstallManager? mockInstallManager,
  BleControllerInterface? mockBleController,
  ErrorHandlingService? mockErrorHandlingService,
  AppUpdateManager? mockAppUpdateManager,
  CommandParameterStorageService? mockCommandParameterStorageService,
  CommandRepositoryInterface? mockCommandRepository,
  RoleService? mockRoleService,
}) {
  // Register mock services if provided, otherwise use defaults
  if (mockNetworkService != null) {
    getIt.registerSingleton<NetworkService>(mockNetworkService);
  }

  if (mockNotificationService != null) {
    getIt.registerSingleton<NotificationService>(mockNotificationService);
  }

  if (mockPermissionService != null) {
    getIt.registerSingleton<PermissionService>(mockPermissionService);
  }

  if (mockBleService != null) {
    getIt.registerSingleton<BleService>(mockBleService);
  }

  if (mockUpdateService != null) {
    getIt.registerSingleton<UpdateService>(mockUpdateService);
  }

  if (mockUpdateChecker != null) {
    getIt.registerSingleton<UpdateChecker>(mockUpdateChecker);
  }

  if (mockDownloadManager != null) {
    getIt.registerSingleton<DownloadManager>(mockDownloadManager);
  }

  if (mockInstallManager != null) {
    getIt.registerSingleton<InstallManager>(mockInstallManager);
  }

  if (mockBleController != null) {
    getIt.registerSingleton<BleControllerInterface>(mockBleController);
  }

  if (mockErrorHandlingService != null) {
    getIt.registerSingleton<ErrorHandlingService>(mockErrorHandlingService);
  }

  if (mockAppUpdateManager != null) {
    getIt.registerSingleton<AppUpdateManager>(mockAppUpdateManager);
  }

  if (mockCommandParameterStorageService != null) {
    getIt.registerSingleton<CommandParameterStorageService>(
      mockCommandParameterStorageService,
    );
  }

  if (mockCommandRepository != null) {
    getIt.registerSingleton<CommandRepositoryInterface>(mockCommandRepository);
  }

  if (mockRoleService != null) {
    getIt.registerSingleton<RoleService>(mockRoleService);
  }

  _isInitialized = true;
}
