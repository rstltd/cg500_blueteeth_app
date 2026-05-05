import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';
import 'package:cg500_blueteeth_app/models/device_info.dart';
import 'package:cg500_blueteeth_app/services/device_info_tracker.dart';
import '../mocks/mock_ble_controller.dart';

BleDeviceModel _connectedDevice() => const BleDeviceModel(
      id: 'AA:BB:CC:DD:EE:FF',
      name: 'CG500',
      displayName: 'CG500',
      rssi: -60,
      connectionState: BleConnectionState.connected,
    );

BleDeviceModel _disconnectedDevice() => const BleDeviceModel(
      id: 'AA:BB:CC:DD:EE:FF',
      name: 'CG500',
      displayName: 'CG500',
      rssi: -60,
      connectionState: BleConnectionState.disconnected,
    );

void main() {
  late MockBleController mockController;
  late DeviceInfoTracker tracker;

  setUp(() async {
    mockController = MockBleController();
    await mockController.initialize();
    tracker = DeviceInfoTracker(controller: mockController);
  });

  tearDown(() {
    tracker.dispose();
    mockController.dispose();
  });

  group('DeviceInfoTracker', () {
    test('starts with an empty DeviceInfo', () {
      expect(tracker.current, const DeviceInfo());
      expect(tracker.current.firmwareName, isNull);
      expect(tracker.current.apn, isNull);
    });

    test('updates current after a parseable response line', () async {
      mockController.emitCommandResponse('FW:CG500-v1.2.3');
      await Future<void>.delayed(Duration.zero);

      expect(tracker.current.firmwareName, 'CG500-v1.2.3');
    });

    test('accumulates fields across multiple lines', () async {
      mockController.emitCommandResponse('FW:CG500-v1.2.3');
      mockController.emitCommandResponse('APN:internet');
      mockController.emitCommandResponse('REBOOT:6');
      await Future<void>.delayed(Duration.zero);

      expect(tracker.current.firmwareName, 'CG500-v1.2.3');
      expect(tracker.current.apn, 'internet');
      expect(tracker.current.rebootHour, '6');
    });

    test(r'later $INFO overwrites earlier values for the same field',
        () async {
      mockController.emitCommandResponse('APN:internet');
      mockController.emitCommandResponse('APN:internet2');
      await Future<void>.delayed(Duration.zero);

      expect(tracker.current.apn, 'internet2');
    });

    test('ignores lines that do not match any pattern', () async {
      mockController.emitCommandResponse('OK');
      mockController.emitCommandResponse('arbitrary device noise');
      await Future<void>.delayed(Duration.zero);

      expect(tracker.current, const DeviceInfo());
    });

    test('infoStream emits when a field changes', () async {
      final emissions = <DeviceInfo>[];
      final sub = tracker.infoStream.listen(emissions.add);

      mockController.emitCommandResponse('FW:CG500-v1.2.3');
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
      expect(emissions.first.firmwareName, 'CG500-v1.2.3');

      await sub.cancel();
    });

    test('infoStream does not emit for non-matching lines', () async {
      final emissions = <DeviceInfo>[];
      final sub = tracker.infoStream.listen(emissions.add);

      mockController.emitCommandResponse('OK');
      await Future<void>.delayed(Duration.zero);

      expect(emissions, isEmpty);
      await sub.cancel();
    });

    test('disconnect resets current to empty DeviceInfo', () async {
      mockController.emitCommandResponse('FW:CG500-v1.2.3');
      await Future<void>.delayed(Duration.zero);
      expect(tracker.current.firmwareName, isNotNull);

      mockController.emitConnectedDevice(_disconnectedDevice());
      await Future<void>.delayed(Duration.zero);

      expect(tracker.current, const DeviceInfo());
    });

    test('reconnect after disconnect re-accumulates from a clean slate',
        () async {
      mockController.emitCommandResponse('APN:old');
      await Future<void>.delayed(Duration.zero);

      mockController.emitConnectedDevice(_disconnectedDevice());
      await Future<void>.delayed(Duration.zero);

      mockController.emitConnectedDevice(_connectedDevice());
      mockController.emitCommandResponse('APN:fresh');
      await Future<void>.delayed(Duration.zero);

      expect(tracker.current.apn, 'fresh');
    });

    test('connect events do not erase accumulated state', () async {
      mockController.emitCommandResponse('FW:CG500-v1.2.3');
      mockController.emitConnectedDevice(_connectedDevice());
      await Future<void>.delayed(Duration.zero);

      expect(tracker.current.firmwareName, 'CG500-v1.2.3');
    });
  });
}
