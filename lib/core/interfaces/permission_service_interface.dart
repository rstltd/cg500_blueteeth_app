/// Interface for permission handling services.
///
/// Implementations of this interface provide platform-specific permission
/// management for Bluetooth and location services.
abstract class PermissionServiceInterface {
  /// Check if the app has all required Bluetooth permissions.
  ///
  /// Returns `true` if all necessary permissions are granted.
  Future<bool> hasBluetoothPermissions();

  /// Request Bluetooth permissions from the user.
  ///
  /// Returns `true` if all permissions were granted after the request.
  Future<bool> requestBluetoothPermissions();

  /// Check if location services are enabled on the device.
  ///
  /// This is often required for BLE scanning on Android.
  Future<bool> isLocationEnabled();

  /// Open the device's app settings page.
  ///
  /// Useful when permissions have been permanently denied and the user
  /// needs to manually enable them.
  Future<void> openAppSettings();
}
