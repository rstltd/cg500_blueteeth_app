import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';
import '../core/interfaces/permission_service_interface.dart';

/// Service for handling Bluetooth and location permissions.
///
/// This service implements [PermissionServiceInterface] and can be used
/// with dependency injection for improved testability.
///
/// Use [PermissionService.withDependencies()] or [PermissionService()]
/// constructor and register via service locator for production use.
class PermissionService implements PermissionServiceInterface {
  /// Default constructor for dependency injection via service locator.
  PermissionService();

  /// Named constructor for dependency injection (alias for default constructor).
  /// Use this when creating instances via the service locator.
  PermissionService.withDependencies();

  @override
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

  @override
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
  @override
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
  @override
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