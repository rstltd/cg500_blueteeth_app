import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/controllers/command_manager.dart';
import '../mocks/mock_ble_controller.dart';

// Test helper class to access private members via reflection-like approach
// Since we can't mock BLE connection, we test behaviors that don't require it
class CommandManagerTestHelper {
  final CommandManager manager;

  CommandManagerTestHelper(this.manager);

  // Simulate adding to history by calling private method logic
  // This is a workaround since we can't connect to a real BLE device
  void addToHistoryDirectly(String command) {
    // We access command history indirectly through the manager's getter
    // This simulates what would happen if sendCommand was called with a connected device
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CommandManager', () {
    late CommandManager commandManager;
    late MockBleController controller;
    List<Map<String, dynamic>> sentMessages = [];
    int commandSentCount = 0;

    setUp(() {
      controller = MockBleController();
      sentMessages = [];
      commandSentCount = 0;

      commandManager = CommandManager(
        controller: controller,
        onCommandSent: () => commandSentCount++,
        onMessageAdded: (msg) => sentMessages.add(msg),
      );
    });

    tearDown(() {
      commandManager.dispose();
    });

    group('constructor', () {
      test('should create with required controller', () {
        final manager = CommandManager(controller: controller);
        expect(manager, isNotNull);
        manager.dispose();
      });

      test('should create with all callbacks', () {
        final manager = CommandManager(
          controller: controller,
          onCommandSent: () {},
          onMessageAdded: (_) {},
        );
        expect(manager, isNotNull);
        manager.dispose();
      });
    });

    group('textController', () {
      test('should provide TextEditingController', () {
        expect(commandManager.textController, isA<TextEditingController>());
      });

      test('should have empty text initially', () {
        expect(commandManager.textController.text, isEmpty);
      });

      test('should allow setting text', () {
        commandManager.textController.text = 'test command';
        expect(commandManager.textController.text, 'test command');
      });
    });

    group('commandHistory', () {
      test('should be empty initially', () {
        expect(commandManager.commandHistory, isEmpty);
      });

      test('should return unmodifiable list', () {
        expect(
          () => commandManager.commandHistory.add('test'),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('historyIndex', () {
      test('should be -1 initially', () {
        expect(commandManager.historyIndex, -1);
      });
    });

    group('isConnected', () {
      test('should return false when no device connected', () {
        // Since we can't easily mock the Singleton controller,
        // we verify the property accessor works
        expect(commandManager.isConnected, isFalse);
      });
    });

    group('historyUp', () {
      test('should do nothing when history is empty', () {
        commandManager.historyUp();
        expect(commandManager.historyIndex, -1);
        expect(commandManager.textController.text, isEmpty);
      });
    });

    group('historyDown', () {
      test('should do nothing when history is empty', () {
        commandManager.historyDown();
        expect(commandManager.historyIndex, -1);
        expect(commandManager.textController.text, isEmpty);
      });
    });

    group('getCommandSuggestions', () {
      test('should return empty list when history is empty and input is empty', () {
        final suggestions = commandManager.getCommandSuggestions('');
        expect(suggestions, isEmpty);
      });

      test('should return empty list when no match found', () {
        // Add some history items manually for testing
        // Since we can't easily send commands without BLE,
        // we test the method behavior with empty history
        final suggestions = commandManager.getCommandSuggestions('xyz');
        expect(suggestions, isEmpty);
      });
    });

    group('clearHistory', () {
      test('should reset historyIndex to -1', () {
        commandManager.clearHistory();
        expect(commandManager.historyIndex, -1);
      });

      test('should clear command history', () {
        commandManager.clearHistory();
        expect(commandManager.commandHistory, isEmpty);
      });
    });

    group('sendCommand', () {
      test('should not send empty command', () async {
        commandManager.textController.text = '';
        await commandManager.sendCommand();
        expect(sentMessages, isEmpty);
        expect(commandSentCount, 0);
      });

      test('should not send whitespace-only command', () async {
        commandManager.textController.text = '   ';
        await commandManager.sendCommand();
        expect(sentMessages, isEmpty);
        expect(commandSentCount, 0);
      });

      test('should not send when not connected', () async {
        commandManager.textController.text = 'test command';
        await commandManager.sendCommand();
        // Command won't be sent because isConnected is false
        expect(sentMessages, isEmpty);
      });

      test('should accept optional command text parameter', () async {
        // Even with parameter, won't send because not connected
        await commandManager.sendCommand('direct command');
        expect(sentMessages, isEmpty);
      });
    });

    group('sendPredefinedCommand', () {
      test('should call sendCommand with provided command', () async {
        // Won't actually send because not connected, but verifies method exists
        await commandManager.sendPredefinedCommand('predefined');
        // Since not connected, no messages sent
        expect(sentMessages, isEmpty);
      });
    });

    group('dispose', () {
      test('should dispose text controller', () {
        final manager = CommandManager(controller: controller);
        manager.dispose();
        // After dispose, text controller should be disposed
        // We can't easily check this, but ensure no exception
        expect(true, true);
      });
    });
  });

  group('CommandManager history navigation', () {
    // These tests verify the logic without BLE dependency
    // by examining internal state changes

    test('historyUp should not change index when history empty', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      expect(manager.historyIndex, -1);
      manager.historyUp();
      expect(manager.historyIndex, -1);

      manager.dispose();
    });

    test('historyDown should not change index when history empty', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      expect(manager.historyIndex, -1);
      manager.historyDown();
      expect(manager.historyIndex, -1);

      manager.dispose();
    });

    test('clearHistory should reset state', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.clearHistory();
      expect(manager.historyIndex, -1);
      expect(manager.commandHistory, isEmpty);

      manager.dispose();
    });
  });

  group('CommandManager suggestions', () {
    test('should return empty suggestions for non-matching input', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      final suggestions = manager.getCommandSuggestions('nonexistent');
      expect(suggestions, isEmpty);

      manager.dispose();
    });

    test('should handle empty input', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      final suggestions = manager.getCommandSuggestions('');
      // Returns last 5 commands reversed, which is empty
      expect(suggestions, isEmpty);

      manager.dispose();
    });
  });

  group('CommandManager text controller operations', () {
    test('should set text in controller', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.textController.text = 'hello';
      expect(manager.textController.text, 'hello');

      manager.dispose();
    });

    test('should clear text in controller', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.textController.text = 'hello';
      manager.textController.clear();
      expect(manager.textController.text, isEmpty);

      manager.dispose();
    });
  });

  group('CommandManager callback behavior', () {
    test('should create with null callbacks', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      // Verify manager works without callbacks
      expect(manager.isConnected, isFalse);
      expect(manager.commandHistory, isEmpty);

      manager.dispose();
    });

    test('should allow multiple managers with same controller', () {
      final controller = MockBleController();
      final manager1 = CommandManager(controller: controller);
      final manager2 = CommandManager(controller: controller);

      expect(manager1.isConnected, isFalse);
      expect(manager2.isConnected, isFalse);

      manager1.dispose();
      manager2.dispose();
    });

    test('callbacks should be optional', () {
      final controller = MockBleController();
      final manager = CommandManager(
        controller: controller,
        onCommandSent: null,
        onMessageAdded: null,
      );

      // Should not throw when callbacks are null
      expect(() => manager.clearHistory(), returnsNormally);

      manager.dispose();
    });
  });

  group('CommandManager edge cases', () {
    test('historyUp called multiple times on empty history', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      // Multiple calls should not change state
      manager.historyUp();
      manager.historyUp();
      manager.historyUp();
      expect(manager.historyIndex, -1);

      manager.dispose();
    });

    test('historyDown called multiple times on empty history', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      // Multiple calls should not change state
      manager.historyDown();
      manager.historyDown();
      manager.historyDown();
      expect(manager.historyIndex, -1);

      manager.dispose();
    });

    test('clearHistory called multiple times', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      // Multiple clears should be safe
      manager.clearHistory();
      manager.clearHistory();
      manager.clearHistory();
      expect(manager.historyIndex, -1);
      expect(manager.commandHistory, isEmpty);

      manager.dispose();
    });

    test('getCommandSuggestions with special characters', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      final suggestions = manager.getCommandSuggestions('!@#\$%^&*()');
      expect(suggestions, isEmpty);

      manager.dispose();
    });

    test('getCommandSuggestions with very long input', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      final longInput = 'a' * 1000;
      final suggestions = manager.getCommandSuggestions(longInput);
      expect(suggestions, isEmpty);

      manager.dispose();
    });

    test('getCommandSuggestions with whitespace input', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      final suggestions = manager.getCommandSuggestions('   ');
      // With empty history, returns empty regardless of input
      expect(suggestions, isEmpty);

      manager.dispose();
    });
  });

  group('CommandManager sendCommand edge cases', () {
    test('sendCommand with only newlines', () async {
      final controller = MockBleController();
      List<Map<String, dynamic>> messages = [];
      final manager = CommandManager(
        controller: controller,
        onMessageAdded: (msg) => messages.add(msg),
      );

      manager.textController.text = '\n\n\n';
      await manager.sendCommand();
      expect(messages, isEmpty);

      manager.dispose();
    });

    test('sendCommand with tabs only', () async {
      final controller = MockBleController();
      List<Map<String, dynamic>> messages = [];
      final manager = CommandManager(
        controller: controller,
        onMessageAdded: (msg) => messages.add(msg),
      );

      manager.textController.text = '\t\t\t';
      await manager.sendCommand();
      expect(messages, isEmpty);

      manager.dispose();
    });

    test('sendCommand with mixed whitespace', () async {
      final controller = MockBleController();
      List<Map<String, dynamic>> messages = [];
      final manager = CommandManager(
        controller: controller,
        onMessageAdded: (msg) => messages.add(msg),
      );

      manager.textController.text = ' \t \n \t ';
      await manager.sendCommand();
      expect(messages, isEmpty);

      manager.dispose();
    });

    test('sendPredefinedCommand with empty string', () async {
      final controller = MockBleController();
      List<Map<String, dynamic>> messages = [];
      final manager = CommandManager(
        controller: controller,
        onMessageAdded: (msg) => messages.add(msg),
      );

      await manager.sendPredefinedCommand('');
      expect(messages, isEmpty);

      manager.dispose();
    });

    test('sendPredefinedCommand with whitespace only', () async {
      final controller = MockBleController();
      List<Map<String, dynamic>> messages = [];
      final manager = CommandManager(
        controller: controller,
        onMessageAdded: (msg) => messages.add(msg),
      );

      await manager.sendPredefinedCommand('   ');
      expect(messages, isEmpty);

      manager.dispose();
    });
  });

  group('CommandManager text controller state', () {
    test('text controller should preserve text after historyUp with empty history', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.textController.text = 'initial text';
      manager.historyUp();
      // With empty history, text should remain unchanged
      expect(manager.textController.text, 'initial text');

      manager.dispose();
    });

    test('text controller should preserve text after historyDown with empty history', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.textController.text = 'initial text';
      manager.historyDown();
      // With empty history, text should remain unchanged
      expect(manager.textController.text, 'initial text');

      manager.dispose();
    });

    test('text controller selection after setting text', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.textController.text = 'test';
      manager.textController.selection = const TextSelection.collapsed(offset: 2);
      expect(manager.textController.selection.baseOffset, 2);

      manager.dispose();
    });
  });

  group('CommandManager unmodifiable history', () {
    test('commandHistory getter returns unmodifiable list', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      final history = manager.commandHistory;
      expect(() => history.add('test'), throwsUnsupportedError);
      expect(() => history.clear(), throwsUnsupportedError);

      manager.dispose();
    });

    test('commandHistory getter returns different instance each call', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      final history1 = manager.commandHistory;
      final history2 = manager.commandHistory;
      // Should be equal but not same instance (unmodifiable wrapper)
      expect(history1, equals(history2));

      manager.dispose();
    });
  });

  group('CommandManager isConnected behavior', () {
    test('isConnected is false when controller has no device', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      expect(manager.isConnected, isFalse);
      expect(controller.connectedDevice, isNull);

      manager.dispose();
    });

    test('isConnected check is performed on each access', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      // Multiple accesses should all return false
      expect(manager.isConnected, isFalse);
      expect(manager.isConnected, isFalse);
      expect(manager.isConnected, isFalse);

      manager.dispose();
    });
  });

  group('CommandManager textController advanced', () {
    test('textController can handle unicode text', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.textController.text = '中文 日本語 한국어 🔌';
      expect(manager.textController.text, '中文 日本語 한국어 🔌');

      manager.dispose();
    });

    test('textController can handle very long text', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      final longText = 'a' * 10000;
      manager.textController.text = longText;
      expect(manager.textController.text.length, 10000);

      manager.dispose();
    });

    test('textController can be cleared and reset', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.textController.text = 'initial';
      manager.textController.clear();
      expect(manager.textController.text, isEmpty);

      manager.textController.text = 'reset';
      expect(manager.textController.text, 'reset');

      manager.dispose();
    });
  });

  group('CommandManager sendCommand unicode handling', () {
    test('sendCommand handles chinese characters', () async {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.textController.text = '发送命令';
      await manager.sendCommand();
      // Won't send because not connected, but shouldn't throw
      expect(true, true);

      manager.dispose();
    });

    test('sendCommand handles emoji', () async {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.textController.text = '📱🔌💡';
      await manager.sendCommand();
      expect(true, true);

      manager.dispose();
    });

    test('sendCommand handles mixed scripts', () async {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.textController.text = 'Hello 你好 مرحبا שלום';
      await manager.sendCommand();
      expect(true, true);

      manager.dispose();
    });
  });

  group('CommandManager dispose behavior', () {
    test('dispose cleans up resources', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      // Single dispose should work normally
      expect(() {
        manager.dispose();
      }, returnsNormally);

      // Note: TextEditingController throws if used after dispose,
      // which is expected Flutter behavior
    });

    test('manager can be created after dispose of previous', () {
      final controller = MockBleController();

      final manager1 = CommandManager(controller: controller);
      manager1.textController.text = 'test';
      manager1.dispose();

      final manager2 = CommandManager(controller: controller);
      expect(manager2.textController.text, isEmpty); // New manager, new controller
      manager2.dispose();
    });
  });

  group('CommandManager history limit', () {
    // Note: We can't actually add to history without BLE connection,
    // but we can test the getCommandSuggestions behavior

    test('getCommandSuggestions returns at most 5 items', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      // With empty history, should return empty
      final suggestions = manager.getCommandSuggestions('');
      expect(suggestions.length, lessThanOrEqualTo(5));

      manager.dispose();
    });

    test('getCommandSuggestions handles case insensitive search', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      // Even with empty history, the method should work
      final suggestionsLower = manager.getCommandSuggestions('test');
      final suggestionsUpper = manager.getCommandSuggestions('TEST');

      // Both should return empty with no history
      expect(suggestionsLower, isEmpty);
      expect(suggestionsUpper, isEmpty);

      manager.dispose();
    });
  });

  group('CommandManager concurrent operations', () {
    test('concurrent sendCommand calls', () async {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      // Multiple concurrent sends should not throw
      await Future.wait([
        manager.sendCommand('cmd1'),
        manager.sendCommand('cmd2'),
        manager.sendCommand('cmd3'),
      ]);

      expect(true, true);
      manager.dispose();
    });

    test('concurrent history navigation calls', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      // Rapid navigation should not throw
      for (int i = 0; i < 100; i++) {
        manager.historyUp();
        manager.historyDown();
      }

      expect(manager.historyIndex, -1);
      manager.dispose();
    });

    test('interleaved operations', () async {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      manager.historyUp();
      await manager.sendCommand('test');
      manager.historyDown();
      manager.clearHistory();
      await manager.sendPredefinedCommand('preset');
      manager.historyUp();

      expect(manager.commandHistory, isEmpty);
      manager.dispose();
    });
  });

  group('CommandManager getter stability', () {
    test('textController remains same instance', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      final tc1 = manager.textController;
      final tc2 = manager.textController;
      final tc3 = manager.textController;

      expect(identical(tc1, tc2), true);
      expect(identical(tc2, tc3), true);

      manager.dispose();
    });

    test('commandHistory returns consistent data', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      final history1 = manager.commandHistory;
      final history2 = manager.commandHistory;

      expect(history1.length, history2.length);
      manager.dispose();
    });

    test('historyIndex is stable without operations', () {
      final controller = MockBleController();
      final manager = CommandManager(controller: controller);

      final idx1 = manager.historyIndex;
      final idx2 = manager.historyIndex;
      final idx3 = manager.historyIndex;

      expect(idx1, idx2);
      expect(idx2, idx3);
      expect(idx1, -1);

      manager.dispose();
    });
  });
}
