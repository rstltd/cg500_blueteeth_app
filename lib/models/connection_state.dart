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
        return 'Disconnected';
      case BleConnectionState.connecting:
        return 'Connecting...';
      case BleConnectionState.connected:
        return 'Connected';
      case BleConnectionState.disconnecting:
        return 'Disconnecting...';
    }
  }

  bool get isConnected => this == BleConnectionState.connected;
  bool get isDisconnected => this == BleConnectionState.disconnected;
  bool get isTransitioning => 
      this == BleConnectionState.connecting || 
      this == BleConnectionState.disconnecting;
}