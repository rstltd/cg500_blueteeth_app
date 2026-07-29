import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/l10n/app_strings.dart';
import 'package:cg500_blueteeth_app/models/ble_device.dart';
import 'package:cg500_blueteeth_app/models/connection_state.dart';
import 'package:cg500_blueteeth_app/services/command_log_service.dart';
import '../mocks/mock_ble_controller.dart';

void main() {
  late MockBleController controller;
  late CommandLogService log;

  setUp(() {
    controller = MockBleController();
    log = CommandLogService(controller: controller);
  });

  tearDown(() {
    log.dispose();
    controller.dispose();
  });

  MessageData command(String text) =>
      MessageData(text: text, isCommand: true, timestamp: DateTime.now());

  // Stream events are delivered asynchronously, so every emit has to be
  // followed by a turn of the event loop before asserting.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  BleDeviceModel connected(String id) => createTestDevice(
        id: id,
        connectionState: BleConnectionState.connected,
      );

  group('CommandLogService lifetime', () {
    // The regression F-005 was: the log used to be instance state on a
    // route-scoped ViewModel, so navigating back to the scanner destroyed it
    // while the BLE connection was still up.
    test('outlives the consumer that renders it', () async {
      log.add(command(r'$INFO'));
      controller.emitCommandResponse('MAC : B01LT0002');
      await settle();
      expect(log.messages, hasLength(2));

      // A route being popped and re-entered: only the consumer goes away, the
      // service is a locator singleton and stays.
      final sub = log.changeStream.listen((_) {});
      await sub.cancel();

      expect(log.messages, hasLength(2));
      expect(log.messages.first.text, r'$INFO');
    });

    test('records responses that arrive with no consumer attached', () async {
      controller.emitCommandResponse('Alarm : 15');
      await settle();
      expect(log.messages.single.text, 'Alarm : 15');
    });
  });

  group('CommandLogService clear semantics', () {
    test('an explicit clear empties the log', () async {
      log.add(command(r'$INFO'));
      log.clear();
      expect(log.messages, isEmpty);
    });

    test('a disconnect does NOT clear', () async {
      log.add(command(r'$INFO'));
      controller.emitConnectedDevice(null);
      await settle();
      expect(log.messages, hasLength(1),
          reason: 'the lines before a drop are what diagnose the drop');
    });

    test('reconnecting to the SAME device does NOT clear', () async {
      controller.emitConnectedDevice(connected('dev-a'));
      await settle();
      log.add(command(r'$INFO'));
      controller.emitConnectedDevice(null);
      await settle();
      controller.emitConnectedDevice(connected('dev-a'));
      await settle();
      expect(log.messages, hasLength(1));
    });

    test('connecting to a DIFFERENT device clears', () async {
      controller.emitConnectedDevice(connected('dev-a'));
      await settle();
      log.add(command(r'$INFO'));
      controller.emitConnectedDevice(connected('dev-b'));
      await settle();
      expect(log.messages, isEmpty, reason: 'a log describes one device');
    });
  });

  group('CommandLogService undecodable text', () {
    // F-001: a factory-fresh device reports an unset Gateway as a long run of
    // raw bytes, which allowMalformed decoding turns into U+FFFD.
    test('collapses a long run of replacement characters', () async {
      final garbage = '�' * 30;
      controller.emitCommandResponse('Gateway : $garbage:20');
      await settle();
      expect(log.messages.single.text,
          contains(AppStrings.undecodableResponseField));
      expect(log.messages.single.text, isNot(contains('�')));
    });

    // Deliberately NOT collapsed: an isolated corruption is the only visible
    // evidence of a link-layer problem (see F-002).
    test('leaves an isolated corruption visible', () async {
      controller.emitCommandResponse('eset h�ur    : 0');
      await settle();
      expect(log.messages.single.text, contains('�'));
      expect(log.messages.single.text,
          isNot(contains(AppStrings.undecodableResponseField)));
    });

    test('leaves clean text untouched', () async {
      controller.emitCommandResponse('Reset hour  : 0');
      await settle();
      expect(log.messages.single.text, 'Reset hour  : 0');
    });
  });

  group('CommandLogService bounds', () {
    test('drops the oldest entries past maxMessages', () async {
      for (var i = 0; i < CommandLogService.maxMessages + 10; i++) {
        log.add(command('cmd $i'));
      }
      expect(log.messages, hasLength(CommandLogService.maxMessages));
      expect(
          log.messages.last.text, 'cmd ${CommandLogService.maxMessages + 9}');
    });
  });
}
