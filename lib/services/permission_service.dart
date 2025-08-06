import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> requestBluetoothPermissions() async {
    try {
      final List<Permission> permissions = [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();
      
      debugPrint('Permission statuses: $statuses');

      return statuses.values.every((status) => 
          status == PermissionStatus.granted || 
          status == PermissionStatus.limited);
          
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
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
          debugPrint('Missing permission: $permission, status: $status');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Error checking permissions: $e');
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

  Future<bool> openAppSettings() async {
    return await openAppSettings();
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