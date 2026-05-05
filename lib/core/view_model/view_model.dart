/// ViewModelProvider pattern for Flutter.
///
/// This library provides a lightweight, custom implementation of the
/// ViewModel pattern for state management in Flutter applications.
///
/// Key components:
/// - [BaseViewModel]: Base class for all ViewModels with lifecycle management
/// - [ViewModelProvider]: Widget that creates and provides ViewModels
/// - [ViewModelBuilder]: Widget for consuming ViewModels from ancestors
///
/// Example usage:
/// ```dart
/// // 1. Create a ViewModel
/// class CounterViewModel extends BaseViewModel {
///   int _count = 0;
///   int get count => _count;
///
///   void increment() {
///     _count++;
///     notifyListeners();
///   }
/// }
///
/// // 2. Provide it to a widget tree
/// ViewModelProvider<CounterViewModel>(
///   create: () => CounterViewModel(),
///   builder: (context, viewModel, child) {
///     return Text('Count: ${viewModel.count}');
///   },
/// )
///
/// // 3. Access from descendants
/// final viewModel = context.viewModel<CounterViewModel>();
/// ```
library;

export 'base_view_model.dart';
export 'view_model_provider.dart';
export 'view_model_builder.dart';
