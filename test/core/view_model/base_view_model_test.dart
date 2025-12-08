import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/core/view_model/view_model.dart';

void main() {
  group('BaseViewModel', () {
    group('lifecycle', () {
      test('should start with correct initial state', () {
        final viewModel = _TestViewModel();

        expect(viewModel.isInitialized, isFalse);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.isDisposed, isFalse);
        expect(viewModel.hasError, isFalse);
        expect(viewModel.errorMessage, isNull);
      });

      test('should set loading state during initialization', () async {
        final viewModel = _TestViewModel();
        final loadingStates = <bool>[];

        viewModel.addListener(() {
          loadingStates.add(viewModel.isLoading);
        });

        await viewModel.initialize();

        // Should have transitioned: false -> true -> false
        expect(loadingStates, contains(true));
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.isInitialized, isTrue);
      });

      test('should only initialize once', () async {
        final viewModel = _TestViewModel();

        await viewModel.initialize();
        final initCount1 = viewModel.initCount;

        await viewModel.initialize();
        final initCount2 = viewModel.initCount;

        expect(initCount1, equals(1));
        expect(initCount2, equals(1));
      });

      test('should set disposed flag on dispose', () {
        final viewModel = _TestViewModel();

        expect(viewModel.isDisposed, isFalse);
        viewModel.dispose();
        expect(viewModel.isDisposed, isTrue);
      });

      test('should call onDispose when disposed', () {
        final viewModel = _TestViewModel();

        viewModel.dispose();

        expect(viewModel.onDisposeCalled, isTrue);
      });

      test('should not initialize after dispose', () async {
        final viewModel = _TestViewModel();

        viewModel.dispose();
        await viewModel.initialize();

        expect(viewModel.isInitialized, isFalse);
        expect(viewModel.initCount, equals(0));
      });
    });

    group('stream subscriptions', () {
      test('should subscribe to stream', () async {
        final viewModel = _StreamTestViewModel();
        final controller = StreamController<int>.broadcast();

        await viewModel.initialize();
        viewModel.subscribeToStream(controller.stream);

        controller.add(1);
        controller.add(2);
        controller.add(3);

        await Future.delayed(Duration.zero);

        expect(viewModel.receivedValues, equals([1, 2, 3]));

        await controller.close();
        viewModel.dispose();
      });

      test('should cancel subscriptions on dispose', () async {
        final viewModel = _StreamTestViewModel();
        final controller = StreamController<int>.broadcast();

        await viewModel.initialize();
        viewModel.subscribeToStream(controller.stream);

        controller.add(1);
        await Future.delayed(Duration.zero);
        expect(viewModel.receivedValues, equals([1]));

        viewModel.dispose();

        // Should not receive values after dispose
        controller.add(2);
        await Future.delayed(Duration.zero);
        expect(viewModel.receivedValues, equals([1]));

        await controller.close();
      });

      test('should not process stream data after dispose', () async {
        final viewModel = _StreamTestViewModel();
        final controller = StreamController<int>.broadcast();

        await viewModel.initialize();
        viewModel.subscribeToStream(controller.stream);

        viewModel.dispose();

        controller.add(1);
        await Future.delayed(Duration.zero);

        expect(viewModel.receivedValues, isEmpty);

        await controller.close();
      });
    });

    group('error handling', () {
      test('should set error message', () {
        final viewModel = _TestViewModel();

        viewModel.setErrorPublic('Test error');

        expect(viewModel.hasError, isTrue);
        expect(viewModel.errorMessage, equals('Test error'));
      });

      test('should clear error message', () {
        final viewModel = _TestViewModel();

        viewModel.setErrorPublic('Test error');
        expect(viewModel.hasError, isTrue);

        viewModel.clearErrorPublic();

        expect(viewModel.hasError, isFalse);
        expect(viewModel.errorMessage, isNull);
      });

      test('should notify listeners on error change', () {
        final viewModel = _TestViewModel();
        var notified = false;

        viewModel.addListener(() {
          notified = true;
        });

        viewModel.setErrorPublic('Error');

        expect(notified, isTrue);
      });

      test('should handle initialization error', () async {
        final viewModel = _FailingViewModel();

        await viewModel.initialize();

        expect(viewModel.hasError, isTrue);
        expect(viewModel.errorMessage, contains('Initialization failed'));
        expect(viewModel.isInitialized, isFalse);
      });
    });

    group('loading state', () {
      test('should notify listeners on loading change', () {
        final viewModel = _TestViewModel();
        var loadingNotifications = 0;

        viewModel.addListener(() {
          loadingNotifications++;
        });

        viewModel.setLoadingPublic(true);
        viewModel.setLoadingPublic(false);

        expect(loadingNotifications, equals(2));
      });

      test('should not notify if loading state unchanged', () {
        final viewModel = _TestViewModel();
        var notificationCount = 0;

        viewModel.addListener(() {
          notificationCount++;
        });

        viewModel.setLoadingPublic(true);
        viewModel.setLoadingPublic(true); // Same state

        expect(notificationCount, equals(1));
      });
    });

    group('safeNotifyListeners', () {
      test('should notify when not disposed', () {
        final viewModel = _TestViewModel();
        var notified = false;

        viewModel.addListener(() {
          notified = true;
        });

        viewModel.safeNotifyListenersPublic();

        expect(notified, isTrue);
      });

      test('should not throw when disposed', () {
        final viewModel = _TestViewModel();

        viewModel.dispose();

        // Should not throw
        expect(() => viewModel.safeNotifyListenersPublic(), returnsNormally);
      });
    });
  });

  group('MountedAwareMixin', () {
    test('should track mounted state', () {
      final viewModel = _MountedAwareViewModel();

      expect(viewModel.isMounted, isFalse);

      viewModel.setMounted(true);
      expect(viewModel.isMounted, isTrue);

      viewModel.setMounted(false);
      expect(viewModel.isMounted, isFalse);
    });

    test('should return false when disposed even if mounted', () {
      final viewModel = _MountedAwareViewModel();

      viewModel.setMounted(true);
      expect(viewModel.isMounted, isTrue);

      viewModel.dispose();
      expect(viewModel.isMounted, isFalse);
    });

    test('runIfMounted should execute when mounted', () {
      final viewModel = _MountedAwareViewModel();
      var executed = false;

      viewModel.setMounted(true);
      viewModel.runIfMounted(() {
        executed = true;
      });

      expect(executed, isTrue);
    });

    test('runIfMounted should not execute when not mounted', () {
      final viewModel = _MountedAwareViewModel();
      var executed = false;

      viewModel.setMounted(false);
      viewModel.runIfMounted(() {
        executed = true;
      });

      expect(executed, isFalse);
    });

    test('runIfMountedAsync should execute when mounted', () async {
      final viewModel = _MountedAwareViewModel();

      viewModel.setMounted(true);
      final result = await viewModel.runIfMountedAsync(() async {
        return 42;
      });

      expect(result, equals(42));
    });

    test('runIfMountedAsync should return null when not mounted', () async {
      final viewModel = _MountedAwareViewModel();

      viewModel.setMounted(false);
      final result = await viewModel.runIfMountedAsync(() async {
        return 42;
      });

      expect(result, isNull);
    });
  });
}

// Test implementations

class _TestViewModel extends BaseViewModel {
  int initCount = 0;
  bool onDisposeCalled = false;

  @override
  Future<void> onInit() async {
    initCount++;
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  void onDispose() {
    onDisposeCalled = true;
    super.onDispose();
  }

  void setErrorPublic(String? message) => setError(message);
  void clearErrorPublic() => clearError();
  void setLoadingPublic(bool loading) => setLoading(loading);
  void safeNotifyListenersPublic() => safeNotifyListeners();
}

class _StreamTestViewModel extends BaseViewModel {
  final List<int> receivedValues = [];

  void subscribeToStream(Stream<int> stream) {
    subscribe<int>(stream, (value) {
      receivedValues.add(value);
    });
  }
}

class _FailingViewModel extends BaseViewModel {
  @override
  Future<void> onInit() async {
    throw Exception('Intentional failure');
  }
}

class _MountedAwareViewModel extends BaseViewModel with MountedAwareMixin {}
