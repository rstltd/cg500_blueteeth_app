import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';

void main() {
  group('BleConnectionState', () {
    group('enum values', () {
      test('should have 4 connection states', () {
        expect(BleConnectionState.values.length, 4);
      });

      test('should contain disconnected state', () {
        expect(BleConnectionState.values, contains(BleConnectionState.disconnected));
      });

      test('should contain connecting state', () {
        expect(BleConnectionState.values, contains(BleConnectionState.connecting));
      });

      test('should contain connected state', () {
        expect(BleConnectionState.values, contains(BleConnectionState.connected));
      });

      test('should contain disconnecting state', () {
        expect(BleConnectionState.values, contains(BleConnectionState.disconnecting));
      });
    });

    group('displayName extension', () {
      test('disconnected should display "Disconnected"', () {
        expect(BleConnectionState.disconnected.displayName, '已斷線');
      });

      test('connecting should display "Connecting..."', () {
        expect(BleConnectionState.connecting.displayName, '連線中...');
      });

      test('connected should display "Connected"', () {
        expect(BleConnectionState.connected.displayName, '已連線');
      });

      test('disconnecting should display "Disconnecting..."', () {
        expect(BleConnectionState.disconnecting.displayName, '斷線中...');
      });
    });

    group('isConnected extension', () {
      test('connected state should return true for isConnected', () {
        expect(BleConnectionState.connected.isConnected, true);
      });

      test('disconnected state should return false for isConnected', () {
        expect(BleConnectionState.disconnected.isConnected, false);
      });

      test('connecting state should return false for isConnected', () {
        expect(BleConnectionState.connecting.isConnected, false);
      });

      test('disconnecting state should return false for isConnected', () {
        expect(BleConnectionState.disconnecting.isConnected, false);
      });
    });

    group('isDisconnected extension', () {
      test('disconnected state should return true for isDisconnected', () {
        expect(BleConnectionState.disconnected.isDisconnected, true);
      });

      test('connected state should return false for isDisconnected', () {
        expect(BleConnectionState.connected.isDisconnected, false);
      });

      test('connecting state should return false for isDisconnected', () {
        expect(BleConnectionState.connecting.isDisconnected, false);
      });

      test('disconnecting state should return false for isDisconnected', () {
        expect(BleConnectionState.disconnecting.isDisconnected, false);
      });
    });

    group('isTransitioning extension', () {
      test('connecting state should return true for isTransitioning', () {
        expect(BleConnectionState.connecting.isTransitioning, true);
      });

      test('disconnecting state should return true for isTransitioning', () {
        expect(BleConnectionState.disconnecting.isTransitioning, true);
      });

      test('connected state should return false for isTransitioning', () {
        expect(BleConnectionState.connected.isTransitioning, false);
      });

      test('disconnected state should return false for isTransitioning', () {
        expect(BleConnectionState.disconnected.isTransitioning, false);
      });
    });
  });
}
