import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/services/error_handling_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorCategory', () {
    test('should have 6 categories', () {
      expect(ErrorCategory.values.length, 6);
    });

    test('should contain bluetooth category', () {
      expect(ErrorCategory.values, contains(ErrorCategory.bluetooth));
    });

    test('should contain permission category', () {
      expect(ErrorCategory.values, contains(ErrorCategory.permission));
    });

    test('should contain network category', () {
      expect(ErrorCategory.values, contains(ErrorCategory.network));
    });

    test('should contain validation category', () {
      expect(ErrorCategory.values, contains(ErrorCategory.validation));
    });

    test('should contain system category', () {
      expect(ErrorCategory.values, contains(ErrorCategory.system));
    });

    test('should contain unknown category', () {
      expect(ErrorCategory.values, contains(ErrorCategory.unknown));
    });

    test('should have correct index order', () {
      expect(ErrorCategory.bluetooth.index, 0);
      expect(ErrorCategory.permission.index, 1);
      expect(ErrorCategory.network.index, 2);
      expect(ErrorCategory.validation.index, 3);
      expect(ErrorCategory.system.index, 4);
      expect(ErrorCategory.unknown.index, 5);
    });
  });

  group('AppError', () {
    test('should create with required parameters', () {
      final error = AppError(
        code: 'TEST_ERROR',
        message: 'Test error message',
        category: ErrorCategory.unknown,
      );

      expect(error.code, 'TEST_ERROR');
      expect(error.message, 'Test error message');
      expect(error.category, ErrorCategory.unknown);
      expect(error.timestamp, isNotNull);
      expect(error.originalError, isNull);
      expect(error.stackTrace, isNull);
      expect(error.retryAction, isNull);
      expect(error.metadata, isNull);
    });

    test('should create with all parameters', () {
      final originalError = Exception('Original');
      final stackTrace = StackTrace.current;
      final retryAction = () {};
      final metadata = {'key': 'value'};
      final timestamp = DateTime(2024, 1, 1);

      final error = AppError(
        code: 'FULL_ERROR',
        message: 'Full error message',
        category: ErrorCategory.system,
        timestamp: timestamp,
        originalError: originalError,
        stackTrace: stackTrace,
        retryAction: retryAction,
        metadata: metadata,
      );

      expect(error.code, 'FULL_ERROR');
      expect(error.message, 'Full error message');
      expect(error.category, ErrorCategory.system);
      expect(error.timestamp, timestamp);
      expect(error.originalError, originalError);
      expect(error.stackTrace, stackTrace);
      expect(error.retryAction, retryAction);
      expect(error.metadata, metadata);
    });

    test('should auto-generate timestamp if not provided', () {
      final before = DateTime.now();
      final error = AppError(
        code: 'TEST',
        message: 'Test',
        category: ErrorCategory.unknown,
      );
      final after = DateTime.now();

      expect(error.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(error.timestamp.isBefore(after.add(const Duration(seconds: 1))), true);
    });

    test('toString should return formatted string', () {
      final error = AppError(
        code: 'TEST_CODE',
        message: 'Test message',
        category: ErrorCategory.bluetooth,
      );

      final str = error.toString();
      expect(str, contains('AppError'));
      expect(str, contains('TEST_CODE'));
      expect(str, contains('Test message'));
      expect(str, contains('bluetooth'));
    });
  });

  group('AppError factory constructors', () {
    group('AppError.bluetooth', () {
      test('should create bluetooth error with basic parameters', () {
        final error = AppError.bluetooth(
          'BLE_DISABLED',
          'Bluetooth is disabled',
        );

        expect(error.code, 'BLE_DISABLED');
        expect(error.message, 'Bluetooth is disabled');
        expect(error.category, ErrorCategory.bluetooth);
      });

      test('should create bluetooth error with all parameters', () {
        final originalError = Exception('BLE error');
        final stackTrace = StackTrace.current;
        final retryAction = () {};
        final metadata = {'deviceId': '12345'};

        final error = AppError.bluetooth(
          'CONNECTION_FAILED',
          'Connection failed',
          originalError: originalError,
          stackTrace: stackTrace,
          retryAction: retryAction,
          metadata: metadata,
        );

        expect(error.code, 'CONNECTION_FAILED');
        expect(error.category, ErrorCategory.bluetooth);
        expect(error.originalError, originalError);
        expect(error.stackTrace, stackTrace);
        expect(error.retryAction, retryAction);
        expect(error.metadata, metadata);
      });
    });

    group('AppError.permission', () {
      test('should create permission error with basic parameters', () {
        final error = AppError.permission(
          'BLUETOOTH_PERMISSION_DENIED',
          'Bluetooth permission denied',
        );

        expect(error.code, 'BLUETOOTH_PERMISSION_DENIED');
        expect(error.message, 'Bluetooth permission denied');
        expect(error.category, ErrorCategory.permission);
      });

      test('should create permission error with retry action', () {
        final retryAction = () {};

        final error = AppError.permission(
          'LOCATION_PERMISSION_DENIED',
          'Location permission denied',
          retryAction: retryAction,
        );

        expect(error.code, 'LOCATION_PERMISSION_DENIED');
        expect(error.category, ErrorCategory.permission);
        expect(error.retryAction, retryAction);
      });
    });

    group('AppError.network', () {
      test('should create network error with basic parameters', () {
        final error = AppError.network(
          'NO_INTERNET',
          'No internet connection',
        );

        expect(error.code, 'NO_INTERNET');
        expect(error.message, 'No internet connection');
        expect(error.category, ErrorCategory.network);
      });

      test('should create network error with original error', () {
        final socketError = const SocketException('Network unreachable');
        final retryAction = () {};

        final error = AppError.network(
          'SOCKET_ERROR',
          'Socket error occurred',
          originalError: socketError,
          retryAction: retryAction,
        );

        expect(error.code, 'SOCKET_ERROR');
        expect(error.category, ErrorCategory.network);
        expect(error.originalError, socketError);
        expect(error.retryAction, retryAction);
      });

      test('should create network error with timeout error', () {
        final timeoutError = TimeoutException('Request timed out');

        final error = AppError.network(
          'TIMEOUT',
          'Request timed out',
          originalError: timeoutError,
        );

        expect(error.code, 'TIMEOUT');
        expect(error.category, ErrorCategory.network);
        expect(error.originalError, isA<TimeoutException>());
      });
    });

    group('AppError.validation', () {
      test('should create validation error', () {
        final error = AppError.validation(
          'INVALID_COMMAND',
          'Command format is invalid',
        );

        expect(error.code, 'INVALID_COMMAND');
        expect(error.message, 'Command format is invalid');
        expect(error.category, ErrorCategory.validation);
      });

      test('should create empty command validation error', () {
        final error = AppError.validation(
          'EMPTY_COMMAND',
          'Command cannot be empty',
        );

        expect(error.code, 'EMPTY_COMMAND');
        expect(error.category, ErrorCategory.validation);
      });

      test('should create command too long validation error', () {
        final error = AppError.validation(
          'COMMAND_TOO_LONG',
          'Command is too long',
        );

        expect(error.code, 'COMMAND_TOO_LONG');
        expect(error.category, ErrorCategory.validation);
      });
    });
  });

  group('UserAction', () {
    test('should create with required parameters', () {
      final action = UserAction(
        label: 'Retry',
        action: () {},
      );

      expect(action.label, 'Retry');
      expect(action.action, isNotNull);
      expect(action.isPrimary, false);
    });

    test('should create primary action', () {
      final action = UserAction(
        label: 'OK',
        action: () {},
        isPrimary: true,
      );

      expect(action.label, 'OK');
      expect(action.isPrimary, true);
    });

    test('should create action with null callback', () {
      const action = UserAction(
        label: 'Cancel',
        action: null,
      );

      expect(action.label, 'Cancel');
      expect(action.action, isNull);
      expect(action.isPrimary, false);
    });

    test('should be const constructible', () {
      const action = UserAction(
        label: 'Dismiss',
        action: null,
        isPrimary: false,
      );

      expect(action.label, 'Dismiss');
    });
  });

  group('ErrorHandlingService', () {
    late ErrorHandlingService service;

    setUp(() {
      service = ErrorHandlingService();
    });

    group('singleton', () {
      test('should return same instance', () {
        final instance1 = ErrorHandlingService();
        final instance2 = ErrorHandlingService();
        expect(identical(instance1, instance2), true);
      });
    });

    group('errorStream', () {
      test('should be available', () {
        expect(service.errorStream, isA<Stream<AppError>>());
      });

      test('should be a broadcast stream', () {
        final sub1 = service.errorStream.listen((_) {});
        final sub2 = service.errorStream.listen((_) {});

        expect(sub1, isNotNull);
        expect(sub2, isNotNull);

        sub1.cancel();
        sub2.cancel();
      });
    });

    group('errorHistory', () {
      test('should be available', () {
        expect(service.errorHistory, isA<List<AppError>>());
      });

      test('should be unmodifiable', () {
        final history = service.errorHistory;
        expect(() => history.add(
          AppError(code: 'TEST', message: 'Test', category: ErrorCategory.unknown)
        ), throwsUnsupportedError);
      });
    });

    group('clearHistory', () {
      test('should not throw', () {
        expect(() => service.clearHistory(), returnsNormally);
      });

      test('should be callable multiple times', () {
        service.clearHistory();
        service.clearHistory();
        service.clearHistory();
        expect(service.errorHistory.isEmpty, true);
      });
    });

    group('dispose', () {
      test('should not throw', () {
        // Create a new instance for dispose test to avoid affecting other tests
        final testService = ErrorHandlingService();
        expect(() => testService.dispose(), returnsNormally);
      });
    });
  });

  group('AppError bluetooth codes', () {
    test('BLE_DISABLED code', () {
      final error = AppError.bluetooth('BLE_DISABLED', 'Bluetooth disabled');
      expect(error.code, 'BLE_DISABLED');
    });

    test('BLE_UNAVAILABLE code', () {
      final error = AppError.bluetooth('BLE_UNAVAILABLE', 'BLE unavailable');
      expect(error.code, 'BLE_UNAVAILABLE');
    });

    test('DEVICE_NOT_FOUND code', () {
      final error = AppError.bluetooth('DEVICE_NOT_FOUND', 'Device not found');
      expect(error.code, 'DEVICE_NOT_FOUND');
    });

    test('CONNECTION_FAILED code', () {
      final error = AppError.bluetooth('CONNECTION_FAILED', 'Connection failed');
      expect(error.code, 'CONNECTION_FAILED');
    });

    test('CONNECTION_LOST code', () {
      final error = AppError.bluetooth('CONNECTION_LOST', 'Connection lost');
      expect(error.code, 'CONNECTION_LOST');
    });

    test('SERVICE_DISCOVERY_FAILED code', () {
      final error = AppError.bluetooth('SERVICE_DISCOVERY_FAILED', 'Service discovery failed');
      expect(error.code, 'SERVICE_DISCOVERY_FAILED');
    });

    test('CHARACTERISTIC_NOT_FOUND code', () {
      final error = AppError.bluetooth('CHARACTERISTIC_NOT_FOUND', 'Characteristic not found');
      expect(error.code, 'CHARACTERISTIC_NOT_FOUND');
    });

    test('WRITE_FAILED code', () {
      final error = AppError.bluetooth('WRITE_FAILED', 'Write failed');
      expect(error.code, 'WRITE_FAILED');
    });

    test('READ_FAILED code', () {
      final error = AppError.bluetooth('READ_FAILED', 'Read failed');
      expect(error.code, 'READ_FAILED');
    });
  });

  group('AppError permission codes', () {
    test('BLUETOOTH_PERMISSION_DENIED code', () {
      final error = AppError.permission('BLUETOOTH_PERMISSION_DENIED', 'BT permission denied');
      expect(error.code, 'BLUETOOTH_PERMISSION_DENIED');
    });

    test('LOCATION_PERMISSION_DENIED code', () {
      final error = AppError.permission('LOCATION_PERMISSION_DENIED', 'Location permission denied');
      expect(error.code, 'LOCATION_PERMISSION_DENIED');
    });

    test('NOTIFICATION_PERMISSION_DENIED code', () {
      final error = AppError.permission('NOTIFICATION_PERMISSION_DENIED', 'Notification permission denied');
      expect(error.code, 'NOTIFICATION_PERMISSION_DENIED');
    });
  });

  group('AppError system codes', () {
    test('INSUFFICIENT_MEMORY code', () {
      final error = AppError(
        code: 'INSUFFICIENT_MEMORY',
        message: 'Out of memory',
        category: ErrorCategory.system,
      );
      expect(error.code, 'INSUFFICIENT_MEMORY');
      expect(error.category, ErrorCategory.system);
    });

    test('FILE_NOT_FOUND code', () {
      final error = AppError(
        code: 'FILE_NOT_FOUND',
        message: 'File not found',
        category: ErrorCategory.system,
      );
      expect(error.code, 'FILE_NOT_FOUND');
      expect(error.category, ErrorCategory.system);
    });

    test('STORAGE_FULL code', () {
      final error = AppError(
        code: 'STORAGE_FULL',
        message: 'Storage full',
        category: ErrorCategory.system,
      );
      expect(error.code, 'STORAGE_FULL');
      expect(error.category, ErrorCategory.system);
    });
  });

  group('AppError edge cases', () {
    test('should handle empty code', () {
      final error = AppError(
        code: '',
        message: 'Error with empty code',
        category: ErrorCategory.unknown,
      );
      expect(error.code, '');
    });

    test('should handle empty message', () {
      final error = AppError(
        code: 'EMPTY_MESSAGE',
        message: '',
        category: ErrorCategory.unknown,
      );
      expect(error.message, '');
    });

    test('should handle very long code', () {
      final longCode = 'A' * 1000;
      final error = AppError(
        code: longCode,
        message: 'Long code test',
        category: ErrorCategory.unknown,
      );
      expect(error.code.length, 1000);
    });

    test('should handle very long message', () {
      final longMessage = 'B' * 10000;
      final error = AppError(
        code: 'LONG_MSG',
        message: longMessage,
        category: ErrorCategory.unknown,
      );
      expect(error.message.length, 10000);
    });

    test('should handle unicode in code and message', () {
      final error = AppError(
        code: '錯誤代碼',
        message: '中文錯誤訊息 日本語メッセージ',
        category: ErrorCategory.unknown,
      );
      expect(error.code, '錯誤代碼');
      expect(error.message, contains('中文'));
      expect(error.message, contains('日本語'));
    });

    test('should handle special characters', () {
      final error = AppError(
        code: 'SPECIAL_!@#\$%^&*()',
        message: 'Message with <html> & "quotes"',
        category: ErrorCategory.unknown,
      );
      expect(error.code, contains('!@#'));
      expect(error.message, contains('<html>'));
    });
  });

  group('UserAction edge cases', () {
    test('should handle empty label', () {
      final action = UserAction(
        label: '',
        action: () {},
      );
      expect(action.label, '');
    });

    test('should handle long label', () {
      final action = UserAction(
        label: 'A very long action label that might overflow the UI',
        action: () {},
      );
      expect(action.label.length, greaterThan(20));
    });

    test('should handle unicode label', () {
      const action = UserAction(
        label: '重試',
        action: null,
      );
      expect(action.label, '重試');
    });

    test('should execute action callback', () {
      var called = false;
      final action = UserAction(
        label: 'Test',
        action: () => called = true,
      );

      action.action?.call();
      expect(called, true);
    });
  });

  group('ErrorHandlingService stress tests', () {
    test('rapid error creation', () {
      for (int i = 0; i < 100; i++) {
        final error = AppError(
          code: 'STRESS_$i',
          message: 'Stress test error $i',
          category: ErrorCategory.values[i % ErrorCategory.values.length],
        );
        expect(error, isNotNull);
      }
    });

    test('rapid singleton access', () {
      for (int i = 0; i < 1000; i++) {
        final service = ErrorHandlingService();
        expect(service, isNotNull);
      }
    });

    test('rapid stream subscription', () {
      final service = ErrorHandlingService();
      final subscriptions = <StreamSubscription>[];

      for (int i = 0; i < 50; i++) {
        subscriptions.add(service.errorStream.listen((_) {}));
      }

      for (final sub in subscriptions) {
        sub.cancel();
      }

      expect(subscriptions.length, 50);
    });
  });

  group('Error categories comprehensive', () {
    test('bluetooth category should be for BLE errors', () {
      final error = AppError.bluetooth('BLE_ERROR', 'BLE error');
      expect(error.category, ErrorCategory.bluetooth);
    });

    test('permission category should be for permission errors', () {
      final error = AppError.permission('PERM_ERROR', 'Permission error');
      expect(error.category, ErrorCategory.permission);
    });

    test('network category should be for network errors', () {
      final error = AppError.network('NET_ERROR', 'Network error');
      expect(error.category, ErrorCategory.network);
    });

    test('validation category should be for validation errors', () {
      final error = AppError.validation('VAL_ERROR', 'Validation error');
      expect(error.category, ErrorCategory.validation);
    });

    test('system category should be manually set', () {
      final error = AppError(
        code: 'SYS_ERROR',
        message: 'System error',
        category: ErrorCategory.system,
      );
      expect(error.category, ErrorCategory.system);
    });

    test('unknown category should be default fallback', () {
      final error = AppError(
        code: 'UNKNOWN_ERROR',
        message: 'Unknown error',
        category: ErrorCategory.unknown,
      );
      expect(error.category, ErrorCategory.unknown);
    });
  });

  group('ErrorHandlingService handleError widget tests', () {
    testWidgets('should handle bluetooth error with context', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      final receivedErrors = <AppError>[];
      final subscription = service.errorStream.listen((error) {
        receivedErrors.add(error);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.bluetooth('BLE_DISABLED', 'Bluetooth is disabled');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger Error'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Dismiss the dialog
      final closeButton = find.text('Close');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }

      expect(receivedErrors.length, 1);
      expect(receivedErrors.first.code, 'BLE_DISABLED');
      expect(receivedErrors.first.category, ErrorCategory.bluetooth);

      await subscription.cancel();
    });

    testWidgets('should handle permission error with context', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      final receivedErrors = <AppError>[];
      final subscription = service.errorStream.listen((error) {
        receivedErrors.add(error);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.permission(
                      'BLUETOOTH_PERMISSION_DENIED',
                      'Permission denied',
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger Error'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Dismiss the dialog
      final closeButton = find.text('Close');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }

      expect(receivedErrors.length, 1);
      expect(receivedErrors.first.category, ErrorCategory.permission);

      await subscription.cancel();
    });

    testWidgets('should handle network error with SocketException', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      final receivedErrors = <AppError>[];
      final subscription = service.errorStream.listen((error) {
        receivedErrors.add(error);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.network(
                      'NO_INTERNET',
                      'No connection',
                      originalError: const SocketException('Network unreachable'),
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger Error'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Dismiss the dialog
      final closeButton = find.text('Close');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }

      expect(receivedErrors.length, 1);
      expect(receivedErrors.first.category, ErrorCategory.network);

      await subscription.cancel();
    });

    testWidgets('should handle network error with TimeoutException', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      final receivedErrors = <AppError>[];
      final subscription = service.errorStream.listen((error) {
        receivedErrors.add(error);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.network(
                      'TIMEOUT',
                      'Request timed out',
                      originalError: TimeoutException('Timed out'),
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger Error'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Dismiss the dialog
      final closeButton = find.text('Close');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }

      expect(receivedErrors.length, 1);
      expect(receivedErrors.first.originalError, isA<TimeoutException>());

      await subscription.cancel();
    });

    testWidgets('should handle validation error with context', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      final receivedErrors = <AppError>[];
      final subscription = service.errorStream.listen((error) {
        receivedErrors.add(error);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.validation('INVALID_COMMAND', 'Invalid');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger Error'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      expect(receivedErrors.length, 1);
      expect(receivedErrors.first.category, ErrorCategory.validation);

      await subscription.cancel();
    });

    testWidgets('should handle system error with context', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      final receivedErrors = <AppError>[];
      final subscription = service.errorStream.listen((error) {
        receivedErrors.add(error);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError(
                      code: 'INSUFFICIENT_MEMORY',
                      message: 'Out of memory',
                      category: ErrorCategory.system,
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger Error'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Dismiss the dialog
      final closeButton = find.text('Close');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }

      expect(receivedErrors.length, 1);
      expect(receivedErrors.first.category, ErrorCategory.system);

      await subscription.cancel();
    });

    testWidgets('should handle unknown error with context', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      final receivedErrors = <AppError>[];
      final subscription = service.errorStream.listen((error) {
        receivedErrors.add(error);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError(
                      code: 'RANDOM_ERROR',
                      message: 'Something went wrong',
                      category: ErrorCategory.unknown,
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger Error'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Dismiss the dialog
      final closeButton = find.text('Close');
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }

      expect(receivedErrors.length, 1);
      expect(receivedErrors.first.category, ErrorCategory.unknown);

      await subscription.cancel();
    });

    testWidgets('should handle error without context', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      final receivedErrors = <AppError>[];
      final subscription = service.errorStream.listen((error) {
        receivedErrors.add(error);
      });

      final error = AppError.bluetooth('BLE_ERROR', 'Error');
      await service.handleError(error, null);

      expect(receivedErrors.length, 1);

      await subscription.cancel();
    });
  });

  group('ErrorHandlingService bluetooth error codes', () {
    testWidgets('should handle BLE_UNAVAILABLE', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.bluetooth('BLE_UNAVAILABLE', 'BLE unavailable');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Bluetooth Error'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle DEVICE_NOT_FOUND', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.bluetooth('DEVICE_NOT_FOUND', 'Device not found');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle CONNECTION_FAILED with retry action', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.bluetooth(
                      'CONNECTION_FAILED',
                      'Connection failed',
                      retryAction: () => retried = true,
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      // Find and tap the Retry button
      final retryButton = find.text('Retry');
      if (retryButton.evaluate().isNotEmpty) {
        await tester.tap(retryButton);
        await tester.pumpAndSettle();
        expect(retried, true);
      } else {
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should handle CONNECTION_LOST', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.bluetooth('CONNECTION_LOST', 'Lost');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle SERVICE_DISCOVERY_FAILED', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.bluetooth('SERVICE_DISCOVERY_FAILED', 'Failed');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle CHARACTERISTIC_NOT_FOUND', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.bluetooth('CHARACTERISTIC_NOT_FOUND', 'Not found');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle WRITE_FAILED', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.bluetooth('WRITE_FAILED', 'Write failed');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle READ_FAILED', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.bluetooth('READ_FAILED', 'Read failed');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });

  group('ErrorHandlingService permission error codes', () {
    testWidgets('should handle LOCATION_PERMISSION_DENIED', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.permission(
                      'LOCATION_PERMISSION_DENIED',
                      'Location denied',
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Permission Required'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle NOTIFICATION_PERMISSION_DENIED', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.permission(
                      'NOTIFICATION_PERMISSION_DENIED',
                      'Notification denied',
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });

  group('ErrorHandlingService validation error codes', () {
    testWidgets('should handle EMPTY_COMMAND', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.validation('EMPTY_COMMAND', 'Empty');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      // Validation errors show snackbar, not dialog
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should handle COMMAND_TOO_LONG', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.validation('COMMAND_TOO_LONG', 'Too long');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('ErrorHandlingService system error codes', () {
    testWidgets('should handle FILE_NOT_FOUND', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError(
                      code: 'FILE_NOT_FOUND',
                      message: 'File not found',
                      category: ErrorCategory.system,
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('System Error'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle STORAGE_FULL', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError(
                      code: 'STORAGE_FULL',
                      message: 'Storage full',
                      category: ErrorCategory.system,
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });

  group('ErrorHandlingService error history', () {
    testWidgets('should add errors to history', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      service.clearHistory(); // Reset history

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.validation('TEST', 'Test');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(service.errorHistory.isNotEmpty, true);
      expect(service.errorHistory.first.code, 'TEST');
    });

    testWidgets('should limit history to 100 errors', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      service.clearHistory();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    for (int i = 0; i < 105; i++) {
                      final error = AppError.validation('ERROR_$i', 'Error $i');
                      await service.handleError(error, null);
                    }
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      expect(service.errorHistory.length, lessThanOrEqualTo(100));
    });
  });

  group('ErrorHandlingService dialog actions', () {
    testWidgets('should tap Grant Permission button', (WidgetTester tester) async {
      final service = ErrorHandlingService();
      bool granted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.permission(
                      'BLUETOOTH_PERMISSION_DENIED',
                      'Permission denied',
                      retryAction: () => granted = true,
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      final grantButton = find.text('Grant Permission');
      if (grantButton.evaluate().isNotEmpty) {
        await tester.tap(grantButton);
        await tester.pumpAndSettle();
        expect(granted, true);
      }
    });

    testWidgets('should tap Open Settings button', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.permission(
                      'BLUETOOTH_PERMISSION_DENIED',
                      'Permission denied',
                    );
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      final settingsButton = find.text('Open Settings');
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('should tap Check Settings for network error', (WidgetTester tester) async {
      final service = ErrorHandlingService();

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final error = AppError.network('NO_INTERNET', 'No internet');
                    await service.handleError(error, context);
                  },
                  child: const Text('Trigger'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger'));
      await tester.pumpAndSettle();

      final checkButton = find.text('Check Settings');
      if (checkButton.evaluate().isNotEmpty) {
        await tester.tap(checkButton);
        await tester.pumpAndSettle();
      }
    });
  });
}
