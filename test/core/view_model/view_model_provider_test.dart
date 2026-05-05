import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cg500_blueteeth_app/core/view_model/view_model.dart';

void main() {
  group('ViewModelProvider', () {
    group('creation and disposal', () {
      testWidgets('should create ViewModel', (tester) async {
        _CounterViewModel? capturedViewModel;

        await tester.pumpWidget(
          MaterialApp(
            home: ViewModelProvider<_CounterViewModel>(
              create: () => _CounterViewModel(),
              builder: (context, viewModel, child) {
                capturedViewModel = viewModel;
                return const Text('Test');
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(capturedViewModel, isNotNull);
        expect(capturedViewModel!.count, equals(0));
      });

      testWidgets('should initialize ViewModel automatically', (tester) async {
        _CounterViewModel? capturedViewModel;

        await tester.pumpWidget(
          MaterialApp(
            home: ViewModelProvider<_CounterViewModel>(
              create: () => _CounterViewModel(),
              builder: (context, viewModel, child) {
                capturedViewModel = viewModel;
                return Text('Count: ${viewModel.count}');
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(capturedViewModel!.isInitialized, isTrue);
      });

      testWidgets('should dispose ViewModel when removed', (tester) async {
        final viewModel = _CounterViewModel();

        await tester.pumpWidget(
          MaterialApp(
            home: ViewModelProvider<_CounterViewModel>(
              create: () => viewModel,
              builder: (context, vm, child) => const Text('Test'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(viewModel.isDisposed, isFalse);

        // Remove the widget
        await tester.pumpWidget(
          const MaterialApp(
            home: Text('Removed'),
          ),
        );

        await tester.pumpAndSettle();

        expect(viewModel.isDisposed, isTrue);
      });

      testWidgets('should call onReady callback', (tester) async {
        var onReadyCalled = false;
        _CounterViewModel? readyViewModel;

        await tester.pumpWidget(
          MaterialApp(
            home: ViewModelProvider<_CounterViewModel>(
              create: () => _CounterViewModel(),
              onReady: (viewModel) {
                onReadyCalled = true;
                readyViewModel = viewModel;
              },
              builder: (context, viewModel, child) => const Text('Test'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(onReadyCalled, isTrue);
        expect(readyViewModel, isNotNull);
        expect(readyViewModel!.isInitialized, isTrue);
      });
    });

    group('accessing ViewModel', () {
      testWidgets('should access ViewModel via of()', (tester) async {
        _CounterViewModel? foundViewModel;

        await tester.pumpWidget(
          MaterialApp(
            home: ViewModelProvider<_CounterViewModel>(
              create: () => _CounterViewModel(),
              builder: (context, viewModel, child) {
                return Builder(
                  builder: (innerContext) {
                    foundViewModel =
                        ViewModelProvider.of<_CounterViewModel>(innerContext);
                    return const Text('Test');
                  },
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(foundViewModel, isNotNull);
      });

      testWidgets('should access ViewModel via context extension',
          (tester) async {
        _CounterViewModel? foundViewModel;

        await tester.pumpWidget(
          MaterialApp(
            home: ViewModelProvider<_CounterViewModel>(
              create: () => _CounterViewModel(),
              builder: (context, viewModel, child) {
                return Builder(
                  builder: (innerContext) {
                    foundViewModel =
                        innerContext.viewModel<_CounterViewModel>();
                    return const Text('Test');
                  },
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(foundViewModel, isNotNull);
      });

      testWidgets('maybeOf should return null when not found', (tester) async {
        _CounterViewModel? foundViewModel;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                foundViewModel =
                    ViewModelProvider.maybeOf<_CounterViewModel>(context);
                return const Text('Test');
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(foundViewModel, isNull);
      });

      testWidgets('of() should throw when not found', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                expect(
                  () => ViewModelProvider.of<_CounterViewModel>(context),
                  throwsA(isA<FlutterError>()),
                );
                return const Text('Test');
              },
            ),
          ),
        );

        await tester.pumpAndSettle();
      });
    });

    group('reactivity', () {
      testWidgets('should rebuild when ViewModel notifies', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ViewModelProvider<_CounterViewModel>(
              create: () => _CounterViewModel(),
              builder: (context, viewModel, child) {
                return Column(
                  children: [
                    Text('Count: ${viewModel.count}'),
                    ElevatedButton(
                      onPressed: viewModel.increment,
                      child: const Text('Increment'),
                    ),
                  ],
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Count: 0'), findsOneWidget);

        // Tap increment button
        await tester.tap(find.text('Increment'));
        await tester.pump();

        expect(find.text('Count: 1'), findsOneWidget);
      });

      testWidgets('should pass child widget', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: ViewModelProvider<_CounterViewModel>(
              create: () => _CounterViewModel(),
              child: const Text('Static Child'),
              builder: (context, viewModel, child) {
                return Column(
                  children: [
                    Text('Count: ${viewModel.count}'),
                    ElevatedButton(
                      onPressed: viewModel.increment,
                      child: const Text('Increment'),
                    ),
                    if (child != null) child,
                  ],
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Static Child'), findsOneWidget);

        // Increment - child should still be there
        await tester.tap(find.text('Increment'));
        await tester.pump();

        expect(find.text('Static Child'), findsOneWidget);
        expect(find.text('Count: 1'), findsOneWidget);
      });
    });

    group('lazy initialization', () {
      testWidgets('should not initialize when lazy is true', (tester) async {
        final viewModel = _CounterViewModel();

        await tester.pumpWidget(
          MaterialApp(
            home: ViewModelProvider<_CounterViewModel>(
              create: () => viewModel,
              lazy: true,
              builder: (context, vm, child) => const Text('Test'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(viewModel.isInitialized, isFalse);
      });
    });
  });

  group('ViewModelBuilder', () {
    testWidgets('should consume ViewModel from ancestor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ViewModelProvider<_CounterViewModel>(
            create: () => _CounterViewModel(),
            builder: (context, viewModel, child) {
              return Column(
                children: [
                  ViewModelBuilder<_CounterViewModel>(
                    builder: (context, vm) {
                      return Text('Nested: ${vm.count}');
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nested: 0'), findsOneWidget);
    });
  });

}

// Test implementations

class _CounterViewModel extends BaseViewModel {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();
  }
}
