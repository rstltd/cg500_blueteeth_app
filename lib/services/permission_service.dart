import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

/// Snapshot of every BLE-related precondition that has to hold before the
/// scanner can run. Produced by [PermissionService.getDetailedStatus].
///
/// The `blockingReason` getter picks the single most important problem so
/// the UI can show one focused error instead of a checklist.
class BluetoothEnvironmentStatus {
  const BluetoothEnvironmentStatus({
    required this.isSupported,
    required this.isAdapterOn,
    required this.hasBluetoothPermission,
    required this.hasLocationPermission,
    required this.isLocationServiceOn,
  });

  final bool isSupported;
  final bool isAdapterOn;
  final bool hasBluetoothPermission;
  final bool hasLocationPermission;
  final bool isLocationServiceOn;

  bool get isReady =>
      isSupported &&
      isAdapterOn &&
      hasBluetoothPermission &&
      hasLocationPermission &&
      isLocationServiceOn;

  /// Returns the AppError code for the highest-priority blocker, or null
  /// when everything is ready. Order mirrors the user-recovery flow:
  /// hardware → adapter → app permission → OS service.
  String? get blockingReason {
    if (!isSupported) return 'BLE_UNAVAILABLE';
    if (!isAdapterOn) return 'BLE_DISABLED';
    if (!hasBluetoothPermission) return 'BLUETOOTH_PERMISSION_DENIED';
    if (!hasLocationPermission) return 'LOCATION_PERMISSION_DENIED';
    if (!isLocationServiceOn) return 'LOCATION_SERVICE_DISABLED';
    return null;
  }
}

/// Service for handling Bluetooth and location permissions.
///
/// This class can be used directly or extended for testing purposes.
///
/// Use [PermissionService.withDependencies()] or [PermissionService()]
/// constructor and register via service locator for production use.
class PermissionService {
  /// Default constructor for dependency injection via service locator.
  PermissionService();

  /// Named constructor for dependency injection (alias for default constructor).
  /// Use this when creating instances via the service locator.
  PermissionService.withDependencies();

  Future<bool> requestBluetoothPermissions() async {
    try {
      final List<Permission> permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();
      
      Logger.debug('Permission statuses: $statuses');

      return statuses.values.every((status) => 
          status == PermissionStatus.granted || 
          status == PermissionStatus.limited);
          
    } catch (e) {
      Logger.error('Failed to request permissions', error: e);
      return false;
    }
  }

  Future<bool> hasBluetoothPermissions() async {
    try {
      final List<Permission> permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];

      for (Permission permission in permissions) {
        PermissionStatus status = await permission.status;
        if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
          Logger.debug('Missing permission: $permission, status: $status');
          return false;
        }
      }

      return true;
    } catch (e) {
      Logger.error('Failed to check permissions', error: e);
      return false;
    }
  }

  /// Whether only the Bluetooth-family permissions (scan + connect + base)
  /// are granted. Splits out from the legacy [hasBluetoothPermissions] so
  /// callers can distinguish "Bluetooth permission missing" from
  /// "Location permission missing".
  Future<bool> hasOnlyBluetoothPermissions() async {
    try {
      final permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ];
      for (final permission in permissions) {
        final status = await permission.status;
        if (status != PermissionStatus.granted &&
            status != PermissionStatus.limited) {
          return false;
        }
      }
      return true;
    } catch (e) {
      Logger.error('Failed to check Bluetooth permission', error: e);
      return false;
    }
  }

  /// Whether the foreground location permission required by Android BLE
  /// scanning is granted.
  Future<bool> hasLocationPermission() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      return status == PermissionStatus.granted ||
          status == PermissionStatus.limited;
    } catch (e) {
      Logger.error('Failed to check location permission', error: e);
      return false;
    }
  }

  /// Aggregate every BLE precondition into one snapshot. The caller is
  /// responsible for supplying the BLE adapter facts because PermissionService
  /// stays free of `flutter_blue_plus` imports.
  Future<BluetoothEnvironmentStatus> getDetailedStatus({
    required bool bleSupported,
    required bool adapterOn,
  }) async {
    final hasBlPerm = await hasOnlyBluetoothPermissions();
    final hasLocPerm = await hasLocationPermission();
    final locOn = await isLocationEnabled();
    return BluetoothEnvironmentStatus(
      isSupported: bleSupported,
      isAdapterOn: adapterOn,
      hasBluetoothPermission: hasBlPerm,
      hasLocationPermission: hasLocPerm,
      isLocationServiceOn: locOn,
    );
  }

  /// Open the system settings page that lets the user toggle location
  /// services on. Returns true on success.
  Future<bool> openLocationSettings() async {
    try {
      // permission_handler exposes openAppSettings only; dispatching
      // to the location-specific page goes through a separate intent.
      // For now, open the app settings page — Android users can navigate
      // from there. iOS treats the two screens identically.
      return await ph.openAppSettings();
    } catch (e) {
      Logger.error('Failed to open location settings', error: e);
      return false;
    }
  }

  Future<PermissionStatus> getBluetoothStatus() async {
    return await Permission.bluetooth.status;
  }

  Future<PermissionStatus> getLocationStatus() async {
    return await Permission.locationWhenInUse.status;
  }

  Future<bool> shouldShowBluetoothRationale() async {
    return await Permission.bluetooth.shouldShowRequestRationale;
  }

  Future<bool> shouldShowLocationRationale() async {
    return await Permission.locationWhenInUse.shouldShowRequestRationale;
  }

  /// Check if location services are enabled on the device.
  Future<bool> isLocationEnabled() async {
    try {
      final status = await Permission.locationWhenInUse.serviceStatus;
      return status == ServiceStatus.enabled;
    } catch (e) {
      Logger.error('Failed to check location service status', error: e);
      return false;
    }
  }

  /// Open the device's app settings page.
  Future<void> openAppSettings() async {
    await openAppSettingsPage();
  }

  /// Open the device's app settings page.
  /// Returns true if settings were opened successfully.
  Future<bool> openAppSettingsPage() async {
    return await ph.openAppSettings();
  }

  String getPermissionStatusDescription(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission granted';
      case PermissionStatus.denied:
        return 'Permission denied';
      case PermissionStatus.restricted:
        return 'Permission restricted';
      case PermissionStatus.limited:
        return 'Permission limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permission permanently denied - please enable in settings';
      case PermissionStatus.provisional:
        return 'Permission provisional';
    }
  }
}