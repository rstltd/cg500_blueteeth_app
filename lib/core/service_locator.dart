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
import '../services/custom_command_service.dart';
import '../services/role_service.dart';
import '../repositories/command_repository.dart';
import '../repositories/custom_command_repository.dart';
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

  // CustomCommandService - persists user-defined BLE commands
  getIt.registerLazySingleton<CustomCommandService>(
    () => CustomCommandService(),
  );

  // Built-in CommandRepository is also exposed as a concrete type so
  // components that need to query the canonical command list (e.g. the
  // custom-command ViewModel checking for built-in collisions) can get
  // it without going through the role- and custom-aware decorator chain.
  getIt.registerLazySingleton<CommandRepository>(
    () => CommandRepository(),
  );

  // CommandRepositoryInterface decorator chain:
  //   built-in -> custom (merges user commands) -> role-aware (filters
  //   by whitelist in normal mode). All UI consumers see only the
  //   outermost wrapper.
  getIt.registerLazySingleton<CommandRepositoryInterface>(
    () => RoleAwareCommandRepository(
      inner: CustomCommandRepository(
        inner: getIt<CommandRepository>(),
        customService: getIt<CustomCommandService>(),
      ),
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
      errorHandlingService: getIt<ErrorHandlingService>(),
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
