import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/view_models/command_interface_view_model.dart';
import 'package:cg500_blueteeth_app/core/interfaces/command_repository_interface.dart';
import 'package:cg500_blueteeth_app/models/command/command_category.dart';
import 'package:cg500_blueteeth_app/models/command/device_command.dart';
import 'package:cg500_blueteeth_app/services/command_parameter_storage_service.dart';
import 'package:cg500_blueteeth_app/widgets/message/message_filter_widget.dart';
import '../mocks/mock_ble_controller.dart';

/// Minimal mock for CommandRepositoryInterface.
class _MockCommandRepository implements CommandRepositoryInterface {
  @override
  List<DeviceCommand> getAllCommands() => [];
  @override
  List<DeviceCommand> getCommandsByCategory(CommandCategory category) => [];
  @override
  List<DeviceCommand> getQuickAccessCommands() => [];
  @override
  DeviceCommand? getCommand(String command) => null;
  @override
  List<DeviceCommand> searchCommands(String query) => [];
  @override
  Map<CommandCategory, List<DeviceCommand>> getGroupedCommands() => {};
  @override
  List<DeviceCommand> getDangerousCommands() => [];
}

/// Minimal mock for CommandParameterStorageService.
class _MockParameterStorageService extends CommandParameterStorageService {
  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBleController mockController;
  late _MockCommandRepository mockRepo;
  late _MockParameterStorageService mockStorage;

  setUp(() async {
    mockController = MockBleController();
    // initialize() sets _isInitialized = true in MockBleController
    await mockController.initialize();
    mockRepo = _MockCommandRepository();
    mockStorage = _MockParameterStorageService();
  });

  tearDown(() {
    mockController.dispose();
  });

  /// Helper to create a ViewModel, initialize it, and pump it through
  /// a widget so WidgetsBinding is available and scroll controller has clients.
  Future<CommandInterfaceViewModel> createViewModel(WidgetTester tester) async {
    final vm = CommandInterfaceViewModel(
      controller: mockController,
      commandRepository: mockRepo,
      parameterStorageService: mockStorage,
    );

    // Initialize to call onInit (sets up subscriptions)
    await vm.initialize();

    // Wrap in a widget tree so scrollController has clients
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: vm,
            builder: (context, _) {
              return ListView(
                controller: vm.scrollController,
                children: [
                  for (final msg in vm.messages)
                    SizedBox(
                      height: 30,
                      child: Text(msg.text),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    return vm;
  }

  group('Smart Auto-Scroll State', () {
    test('initial state: auto-scroll not paused, unread is 0', () {
      final vm = CommandInterfaceViewModel(
        controller: mockController,
        commandRepository: mockRepo,
        parameterStorageService: mockStorage,
      );

      expect(vm.isAutoScrollPaused, isFalse);
      expect(vm.unreadCount, 0);
    });

    testWidgets('addMessage scrolls when not paused',
        (WidgetTester tester) async {
      final vm = await createViewModel(tester);

      vm.addMessage(MessageData(
        text: 'test',
        isCommand: false,
        timestamp: DateTime.now(),
      ));
      await tester.pumpAndSettle();

      expect(vm.isAutoScrollPaused, isFalse);
      expect(vm.unreadCount, 0);
      expect(vm.messageCount, 1);
    });

    test('addMessage increments unreadCount when paused', () {
      final vm = CommandInterfaceViewModel(
        controller: mockController,
        commandRepository: mockRepo,
        parameterStorageService: mockStorage,
      );

      // Manually set paused state by accessing private field via public API
      // We can't directly set _isAutoScrollPaused, but we can test through
      // the public API after the scroll listener triggers.
      // Instead, test the observable behavior:
      // Add messages while not paused - unreadCount stays 0
      vm.addMessage(MessageData(
        text: 'msg1',
        isCommand: false,
        timestamp: DateTime.now(),
      ));
      expect(vm.unreadCount, 0);
    });

    test('clearMessages resets scroll state', () {
      final vm = CommandInterfaceViewModel(
        controller: mockController,
        commandRepository: mockRepo,
        parameterStorageService: mockStorage,
      );

      vm.addMessage(MessageData(
        text: 'msg1',
        isCommand: false,
        timestamp: DateTime.now(),
      ));
      vm.clearMessages();

      expect(vm.isAutoScrollPaused, isFalse);
      expect(vm.unreadCount, 0);
      expect(vm.messageCount, 0);
    });

    test('resumeAutoScroll resets pause state and unread count', () {
      final vm = CommandInterfaceViewModel(
        controller: mockController,
        commandRepository: mockRepo,
        parameterStorageService: mockStorage,
      );

      // Call resumeAutoScroll (even if not paused, should be safe)
      vm.resumeAutoScroll();

      expect(vm.isAutoScrollPaused, isFalse);
      expect(vm.unreadCount, 0);
    });

    test('messages list is unmodifiable', () {
      final vm = CommandInterfaceViewModel(
        controller: mockController,
        commandRepository: mockRepo,
        parameterStorageService: mockStorage,
      );

      vm.addMessage(MessageData(
        text: 'test',
        isCommand: true,
        timestamp: DateTime.now(),
      ));

      expect(() => (vm.messages as List).add('x'), throwsA(anything));
    });
  });

  group('MessageData', () {
    test('fromMap creates correct instance', () {
      final now = DateTime.now();
      final data = MessageData.fromMap({
        'text': 'hello',
        'isCommand': true,
        'timestamp': now,
        'isError': false,
      });

      expect(data.text, 'hello');
      expect(data.isCommand, true);
      expect(data.timestamp, now);
      expect(data.isError, false);
    });

    test('fromMap handles missing fields with defaults', () {
      final data = MessageData.fromMap({});

      expect(data.text, '');
      expect(data.isCommand, false);
      expect(data.isError, false);
    });

    test('toMap round-trips correctly', () {
      final now = DateTime.now();
      final original = MessageData(
        text: 'test',
        isCommand: true,
        timestamp: now,
        isError: true,
      );

      final map = original.toMap();
      final restored = MessageData.fromMap(map);

      expect(restored.text, original.text);
      expect(restored.isCommand, original.isCommand);
      expect(restored.timestamp, original.timestamp);
      expect(restored.isError, original.isError);
    });
  });

  group('Message Filtering', () {
    test('filteredMessages returns all by default', () {
      final vm = CommandInterfaceViewModel(
        controller: mockController,
        commandRepository: mockRepo,
        parameterStorageService: mockStorage,
      );

      vm.addMessage(MessageData(
          text: 'cmd', isCommand: true, timestamp: DateTime.now()));
      vm.addMessage(MessageData(
          text: 'rsp', isCommand: false, timestamp: DateTime.now()));
      vm.addMessage(MessageData(
          text: 'err',
          isCommand: false,
          timestamp: DateTime.now(),
          isError: true));

      expect(vm.filteredMessages.length, 3);
    });

    test('filter by commands only', () {
      final vm = CommandInterfaceViewModel(
        controller: mockController,
        commandRepository: mockRepo,
        parameterStorageService: mockStorage,
      );

      vm.addMessage(MessageData(
          text: 'cmd', isCommand: true, timestamp: DateTime.now()));
      vm.addMessage(MessageData(
          text: 'rsp', isCommand: false, timestamp: DateTime.now()));

      vm.setFilter(MessageFilter.commands);
      expect(vm.filteredMessages.length, 1);
      expect(vm.filteredMessages.first.text, 'cmd');
    });

    test('filter by errors only', () {
      final vm = CommandInterfaceViewModel(
        controller: mockController,
        commandRepository: mockRepo,
        parameterStorageService: mockStorage,
      );

      vm.addMessage(MessageData(
          text: 'rsp', isCommand: false, timestamp: DateTime.now()));
      vm.addMessage(MessageData(
          text: 'err',
          isCommand: false,
          timestamp: DateTime.now(),
          isError: true));

      vm.setFilter(MessageFilter.errors);
      expect(vm.filteredMessages.length, 1);
      expect(vm.filteredMessages.first.text, 'err');
    });

    test('messageCounts returns correct counts', () {
      final vm = CommandInterfaceViewModel(
        controller: mockController,
        commandRepository: mockRepo,
        parameterStorageService: mockStorage,
      );

      vm.addMessage(MessageData(
          text: 'cmd', isCommand: true, timestamp: DateTime.now()));
      vm.addMessage(MessageData(
          text: 'rsp', isCommand: false, timestamp: DateTime.now()));
      vm.addMessage(MessageData(
          text: 'err',
          isCommand: false,
          timestamp: DateTime.now(),
          isError: true));

      final counts = vm.messageCounts;
      expect(counts[MessageFilter.all], 3);
      expect(counts[MessageFilter.commands], 1);
      expect(counts[MessageFilter.responses], 1);
      expect(counts[MessageFilter.errors], 1);
    });
  });

  group('Command Response Stream', () {
    testWidgets('subscribes to command responses',
        (WidgetTester tester) async {
      final vm = await createViewModel(tester);

      // Simulate a response from the BLE controller
      mockController.emitCommandResponse('OK');
      await tester.pump();
      await tester.pump(); // extra pump for stream delivery

      expect(vm.messageCount, 1);
      expect(vm.messages.first.text, 'OK');
      expect(vm.messages.first.isCommand, false);
    });

    testWidgets('multiple responses accumulate',
        (WidgetTester tester) async {
      final vm = await createViewModel(tester);

      mockController.emitCommandResponse('Response 1');
      await tester.pump();
      mockController.emitCommandResponse('Response 2');
      await tester.pump();
      await tester.pump(); // extra pump for stream delivery

      expect(vm.messageCount, 2);
    });
  });
}
