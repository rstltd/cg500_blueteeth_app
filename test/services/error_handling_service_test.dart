import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/services/error_handling_service.dart';
import '../mocks/mock_services.dart';

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
      void retryAction() {}
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
        void retryAction() {}
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
        void retryAction() {}

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
        void retryAction() {}

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

    group('AppError.system', () {
      test('should create system error with basic parameters', () {
        final error = AppError.system(
          'INSUFFICIENT_MEMORY',
          'Out of memory',
        );

        expect(error.code, 'INSUFFICIENT_MEMORY');
        expect(error.message, 'Out of memory');
        expect(error.category, ErrorCategory.system);
      });

      test('should create system error with original error', () {
        final originalError = Exception('System failure');
        void retryAction() {}

        final error = AppError.system(
          'SYSTEM_FAILURE',
          'System failure occurred',
          originalError: originalError,
          retryAction: retryAction,
        );

        expect(error.code, 'SYSTEM_FAILURE');
        expect(error.category, ErrorCategory.system);
        expect(error.originalError, originalError);
        expect(error.retryAction, retryAction);
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

  group('ErrorHandlingService', () {
    late ErrorHandlingService service;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockNotificationService = MockNotificationService();
      service = ErrorHandlingService(
        notificationService: mockNotificationService,
      );
    });

    tearDown(() {
      service.dispose();
      mockNotificationService.dispose();
    });

    group('DI pattern', () {
      test('should create independent instances with forTesting', () {
        final mockNotification1 = MockNotificationService();
        final mockNotification2 = MockNotificationService();
        final instance1 = ErrorHandlingService.forTesting(
          notificationService: mockNotification1,
        );
        final instance2 = ErrorHandlingService.forTesting(
          notificationService: mockNotification2,
        );
        expect(identical(instance1, instance2), false);
        instance1.dispose();
        instance2.dispose();
        mockNotification1.dispose();
        mockNotification2.dispose();
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
        final mockNotification = MockNotificationService();
        final testService = ErrorHandlingService(
          notificationService: mockNotification,
        );
        expect(() => testService.dispose(), returnsNormally);
        mockNotification.dispose();
      });
    });
  });

  group('ErrorHandlingService handleError', () {
    late ErrorHandlingService service;
    late MockNotificationService mockNotificationService;
    late List<AppError> receivedErrors;
    late StreamSubscription<AppError> subscription;

    setUp(() {
      mockNotificationService = MockNotificationService();
      service = ErrorHandlingService.forTesting(
        notificationService: mockNotificationService,
      );
      receivedErrors = [];
      subscription = service.errorStream.listen((error) {
        receivedErrors.add(error);
      });
    });

    tearDown(() {
      subscription.cancel();
      service.dispose();
      mockNotificationService.dispose();
    });

    group('Bluetooth errors', () {
      test('should handle BLE_DISABLED error', () async {
        final error = AppError.bluetooth('BLE_DISABLED', 'BT disabled');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'BLE_DISABLED');
        expect(service.errorHistory.isNotEmpty, true);
      });

      test('should handle BLE_UNAVAILABLE error', () async {
        final error = AppError.bluetooth('BLE_UNAVAILABLE', 'BLE not available');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'BLE_UNAVAILABLE');
      });

      test('should handle DEVICE_NOT_FOUND error', () async {
        final error = AppError.bluetooth('DEVICE_NOT_FOUND', 'Device not found');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'DEVICE_NOT_FOUND');
      });

      test('should handle CONNECTION_FAILED error', () async {
        final error = AppError.bluetooth('CONNECTION_FAILED', 'Connection failed');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'CONNECTION_FAILED');
      });

      test('should handle CONNECTION_LOST error', () async {
        final error = AppError.bluetooth('CONNECTION_LOST', 'Connection lost');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'CONNECTION_LOST');
      });

      test('should handle unknown bluetooth error code', () async {
        final error = AppError.bluetooth('UNKNOWN_BLE_ERROR', 'Custom BLE error message');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'UNKNOWN_BLE_ERROR');
      });
    });

    group('Permission errors', () {
      test('should handle BLUETOOTH_PERMISSION_DENIED error', () async {
        final error = AppError.permission('BLUETOOTH_PERMISSION_DENIED', 'BT permission denied');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'BLUETOOTH_PERMISSION_DENIED');
        expect(receivedErrors.first.category, ErrorCategory.permission);
      });

      test('should handle LOCATION_PERMISSION_DENIED error', () async {
        final error = AppError.permission('LOCATION_PERMISSION_DENIED', 'Location denied');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'LOCATION_PERMISSION_DENIED');
      });
    });

    group('Network errors', () {
      test('should handle SocketException error', () async {
        final socketError = const SocketException('Network unreachable');
        final error = AppError.network(
          'SOCKET_ERROR',
          'Socket error',
          originalError: socketError,
        );
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.originalError, isA<SocketException>());
      });

      test('should handle TimeoutException error', () async {
        final timeoutError = TimeoutException('Request timed out');
        final error = AppError.network(
          'TIMEOUT_ERROR',
          'Timeout error',
          originalError: timeoutError,
        );
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.originalError, isA<TimeoutException>());
      });
    });

    group('Validation errors', () {
      test('should handle INVALID_COMMAND error', () async {
        final error = AppError.validation('INVALID_COMMAND', 'Invalid command');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'INVALID_COMMAND');
      });

      test('should handle EMPTY_COMMAND error', () async {
        final error = AppError.validation('EMPTY_COMMAND', 'Empty command');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'EMPTY_COMMAND');
      });
    });

    group('System errors', () {
      test('should handle INSUFFICIENT_MEMORY error', () async {
        final error = AppError.system('INSUFFICIENT_MEMORY', 'Out of memory');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'INSUFFICIENT_MEMORY');
      });

      test('should handle FILE_NOT_FOUND error', () async {
        final error = AppError.system('FILE_NOT_FOUND', 'File not found');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'FILE_NOT_FOUND');
      });

      test('should handle STORAGE_FULL error', () async {
        final error = AppError.system('STORAGE_FULL', 'Storage full');
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.code, 'STORAGE_FULL');
      });
    });

    group('Unknown errors', () {
      test('should handle unknown category error', () async {
        final error = AppError(
          code: 'UNKNOWN',
          message: 'Unknown error',
          category: ErrorCategory.unknown,
        );
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.category, ErrorCategory.unknown);
      });

      test('should handle unknown error with retry action', () async {
        var retried = false;
        final error = AppError(
          code: 'UNKNOWN_RETRYABLE',
          message: 'Unknown but retryable',
          category: ErrorCategory.unknown,
          retryAction: () => retried = true,
        );
        await service.handleError(error);
        await Future.delayed(Duration.zero);

        expect(receivedErrors.length, 1);
        expect(receivedErrors.first.retryAction, isNotNull);

        receivedErrors.first.retryAction?.call();
        expect(retried, true);
      });
    });
  });

  group('ErrorHandlingService getErrorMessage', () {
    late ErrorHandlingService service;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockNotificationService = MockNotificationService();
      service = ErrorHandlingService(
        notificationService: mockNotificationService,
      );
    });

    tearDown(() {
      service.dispose();
      mockNotificationService.dispose();
    });

    test('should return user-friendly message for BLE_DISABLED', () {
      final error = AppError.bluetooth('BLE_DISABLED', 'BT disabled');
      final message = service.getErrorMessage(error);
      expect(message, contains('Bluetooth is disabled'));
    });

    test('should return user-friendly message for CONNECTION_FAILED', () {
      final error = AppError.bluetooth('CONNECTION_FAILED', 'Failed');
      final message = service.getErrorMessage(error);
      expect(message, contains('Failed to connect'));
    });

    test('should return user-friendly message for SocketException', () {
      final error = AppError.network(
        'NETWORK_ERROR',
        'Error',
        originalError: const SocketException('unreachable'),
      );
      final message = service.getErrorMessage(error);
      expect(message, contains('No internet connection'));
    });

    test('should return user-friendly message for TimeoutException', () {
      final error = AppError.network(
        'TIMEOUT',
        'Error',
        originalError: TimeoutException('timeout'),
      );
      final message = service.getErrorMessage(error);
      expect(message, contains('timed out'));
    });

    test('should return user-friendly message for INVALID_COMMAND', () {
      final error = AppError.validation('INVALID_COMMAND', 'Invalid');
      final message = service.getErrorMessage(error);
      expect(message, contains('command format is invalid'));
    });

    test('should return user-friendly message for INSUFFICIENT_MEMORY', () {
      final error = AppError.system('INSUFFICIENT_MEMORY', 'OOM');
      final message = service.getErrorMessage(error);
      expect(message, contains('Insufficient memory'));
    });

    test('should return generic message for unknown errors', () {
      final error = AppError(
        code: 'UNKNOWN',
        message: 'Unknown',
        category: ErrorCategory.unknown,
      );
      final message = service.getErrorMessage(error);
      expect(message, contains('unexpected error'));
    });
  });

  group('ErrorHandlingService getErrorRecoveryActions', () {
    late ErrorHandlingService service;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockNotificationService = MockNotificationService();
      service = ErrorHandlingService(
        notificationService: mockNotificationService,
      );
    });

    tearDown(() {
      service.dispose();
      mockNotificationService.dispose();
    });

    test('should return Enable Bluetooth action for BLE_DISABLED', () {
      final error = AppError.bluetooth('BLE_DISABLED', 'Disabled', retryAction: () {});
      final actions = service.getErrorRecoveryActions(error);
      expect(actions.length, 1);
      expect(actions.first.label, 'Enable Bluetooth');
      expect(actions.first.isPrimary, true);
    });

    test('should return Retry action for CONNECTION_FAILED', () {
      final error = AppError.bluetooth('CONNECTION_FAILED', 'Failed', retryAction: () {});
      final actions = service.getErrorRecoveryActions(error);
      expect(actions.length, 1);
      expect(actions.first.label, 'Retry');
    });

    test('should return Grant Permission action for permission errors', () {
      final error = AppError.permission('BLUETOOTH_PERMISSION_DENIED', 'Denied', retryAction: () {});
      final actions = service.getErrorRecoveryActions(error);
      expect(actions.length, 1);
      expect(actions.first.label, 'Grant Permission');
    });

    test('should return Retry action for network errors', () {
      final error = AppError.network('NETWORK_ERROR', 'Error', retryAction: () {});
      final actions = service.getErrorRecoveryActions(error);
      expect(actions.length, 1);
      expect(actions.first.label, 'Retry');
    });

    test('should return empty list for validation errors', () {
      final error = AppError.validation('INVALID_COMMAND', 'Invalid');
      final actions = service.getErrorRecoveryActions(error);
      expect(actions, isEmpty);
    });

    test('should return Retry action for system errors with retryAction', () {
      final error = AppError.system('SYSTEM_ERROR', 'Error', retryAction: () {});
      final actions = service.getErrorRecoveryActions(error);
      expect(actions.length, 1);
      expect(actions.first.label, 'Retry');
    });

    test('should return empty list for system errors without retryAction', () {
      final error = AppError.system('SYSTEM_ERROR', 'Error');
      final actions = service.getErrorRecoveryActions(error);
      expect(actions, isEmpty);
    });
  });

  group('ErrorHandlingService error history', () {
    late ErrorHandlingService service;
    late MockNotificationService mockNotificationService;

    setUp(() {
      mockNotificationService = MockNotificationService();
      service = ErrorHandlingService.forTesting(
        notificationService: mockNotificationService,
      );
    });

    tearDown(() {
      service.dispose();
      mockNotificationService.dispose();
    });

    test('should add errors to history in correct order', () async {
      final error1 = AppError.bluetooth('ERROR_1', 'First error');
      final error2 = AppError.bluetooth('ERROR_2', 'Second error');
      final error3 = AppError.bluetooth('ERROR_3', 'Third error');

      await service.handleError(error1);
      await service.handleError(error2);
      await service.handleError(error3);

      expect(service.errorHistory.length, 3);
      expect(service.errorHistory[0].code, 'ERROR_3');
      expect(service.errorHistory[1].code, 'ERROR_2');
      expect(service.errorHistory[2].code, 'ERROR_1');
    });

    test('should limit history to 100 entries', () async {
      for (int i = 0; i < 105; i++) {
        final error = AppError.bluetooth('ERROR_$i', 'Error $i');
        await service.handleError(error);
      }

      expect(service.errorHistory.length, 100);
      expect(service.errorHistory[0].code, 'ERROR_104');
      expect(service.errorHistory[99].code, 'ERROR_5');
    });

    test('clearHistory should remove all entries', () async {
      final error1 = AppError.bluetooth('ERROR_1', 'First error');
      final error2 = AppError.bluetooth('ERROR_2', 'Second error');

      await service.handleError(error1);
      await service.handleError(error2);

      expect(service.errorHistory.length, 2);

      service.clearHistory();
      expect(service.errorHistory.isEmpty, true);
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

    test('should handle unicode in code and message', () {
      final error = AppError(
        code: '錯誤代碼',
        message: '中文錯誤訊息 日本語メッセージ',
        category: ErrorCategory.unknown,
      );
      expect(error.code, '錯誤代碼');
      expect(error.message, contains('中文'));
    });
  });

  group('ErrorCategory extensions', () {
    test('should be usable in switch statements', () {
      String getCategoryName(ErrorCategory category) {
        switch (category) {
          case ErrorCategory.bluetooth:
            return 'BT';
          case ErrorCategory.permission:
            return 'PERM';
          case ErrorCategory.network:
            return 'NET';
          case ErrorCategory.validation:
            return 'VAL';
          case ErrorCategory.system:
            return 'SYS';
          case ErrorCategory.unknown:
            return 'UNK';
        }
      }

      expect(getCategoryName(ErrorCategory.bluetooth), 'BT');
      expect(getCategoryName(ErrorCategory.permission), 'PERM');
      expect(getCategoryName(ErrorCategory.network), 'NET');
      expect(getCategoryName(ErrorCategory.validation), 'VAL');
      expect(getCategoryName(ErrorCategory.system), 'SYS');
      expect(getCategoryName(ErrorCategory.unknown), 'UNK');
    });

    test('should have consistent name property', () {
      expect(ErrorCategory.bluetooth.name, 'bluetooth');
      expect(ErrorCategory.permission.name, 'permission');
      expect(ErrorCategory.network.name, 'network');
      expect(ErrorCategory.validation.name, 'validation');
      expect(ErrorCategory.system.name, 'system');
      expect(ErrorCategory.unknown.name, 'unknown');
    });
  });

  group('AppError with complex metadata', () {
    test('should handle nested metadata', () {
      final error = AppError(
        code: 'NESTED',
        message: 'Nested metadata',
        category: ErrorCategory.system,
        metadata: {
          'device': {
            'id': '12345',
            'name': 'Test Device',
            'services': ['service1', 'service2'],
          },
        },
      );

      expect(error.metadata?['device']?['id'], '12345');
      expect((error.metadata?['device']?['services'] as List).length, 2);
    });

    test('should handle null values in metadata', () {
      final error = AppError(
        code: 'NULL_META',
        message: 'Null in metadata',
        category: ErrorCategory.unknown,
        metadata: {
          'validKey': 'value',
          'nullKey': null,
        },
      );

      expect(error.metadata?['validKey'], 'value');
      expect(error.metadata?['nullKey'], isNull);
    });
  });
}
