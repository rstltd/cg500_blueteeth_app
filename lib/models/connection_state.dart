import '../l10n/app_strings.dart';

enum BleConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

extension BleConnectionStateExtension on BleConnectionState {
  String get displayName {
    switch (this) {
      case BleConnectionState.disconnected:
        return AppStrings.disconnected;
      case BleConnectionState.connecting:
        return AppStrings.connecting;
      case BleConnectionState.connected:
        return AppStrings.connected;
      case BleConnectionState.disconnecting:
        return AppStrings.disconnecting;
    }
  }

  bool get isConnected => this == BleConnectionState.connected;
  bool get isDisconnected => this == BleConnectionState.disconnected;
  bool get isTransitioning => 
      this == BleConnectionState.connecting || 
      this == BleConnectionState.disconnecting;
}