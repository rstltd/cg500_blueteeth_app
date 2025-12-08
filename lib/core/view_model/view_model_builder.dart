import 'package:flutter/widgets.dart';
import 'base_view_model.dart';
import 'view_model_provider.dart';

/// A convenience widget for consuming a ViewModel from an ancestor provider.
///
/// Use this when you have nested widgets that need to access the same ViewModel.
///
/// Usage:
/// ```dart
/// ViewModelBuilder<MyViewModel>(
///   builder: (context, viewModel) {
///     return Text(viewModel.someValue);
///   },
/// )
/// ```
class ViewModelBuilder<T extends BaseViewModel> extends StatelessWidget {
  const ViewModelBuilder({
    super.key,
    required this.builder,
    this.child,
  });

  /// Builder function that receives the ViewModel.
  final Widget Function(BuildContext context, T viewModel) builder;

  /// Optional child widget that doesn't depend on the ViewModel.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModelProvider.of<T>(context);
    return builder(context, viewModel);
  }
}

/// A widget that rebuilds only when a specific selector value changes.
///
/// Use this for fine-grained rebuilds when your ViewModel has many properties
/// but you only care about specific ones.
///
/// Usage:
/// ```dart
/// ViewModelSelector<MyViewModel, String>(
///   selector: (vm) => vm.name,
///   builder: (context, name) {
///     return Text(name);
///   },
/// )
/// ```
class ViewModelSelector<T extends BaseViewModel, S> extends StatefulWidget {
  const ViewModelSelector({
    super.key,
    required this.selector,
    required this.builder,
    this.child,
  });

  /// Function to select a value from the ViewModel.
  final S Function(T viewModel) selector;

  /// Builder function that receives the selected value.
  final Widget Function(BuildContext context, S value, Widget? child) builder;

  /// Optional child widget passed to the builder.
  final Widget? child;

  @override
  State<ViewModelSelector<T, S>> createState() =>
      _ViewModelSelectorState<T, S>();
}

class _ViewModelSelectorState<T extends BaseViewModel, S>
    extends State<ViewModelSelector<T, S>> {
  T? _viewModel;
  S? _selectedValue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateViewModel();
  }

  void _updateViewModel() {
    final newViewModel = ViewModelProvider.of<T>(context);

    if (_viewModel != newViewModel) {
      _viewModel?.removeListener(_onViewModelChanged);
      _viewModel = newViewModel;
      _viewModel!.addListener(_onViewModelChanged);
      _selectedValue = widget.selector(_viewModel!);
    }
  }

  void _onViewModelChanged() {
    final newValue = widget.selector(_viewModel!);

    // Only rebuild if the selected value actually changed
    if (_selectedValue != newValue) {
      setState(() {
        _selectedValue = newValue;
      });
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _selectedValue as S, widget.child);
  }
}

/// A widget that consumes a ViewModel and handles loading/error states.
///
/// Provides built-in widgets for loading and error states.
///
/// Usage:
/// ```dart
/// ViewModelConsumer<MyViewModel>(
///   loadingBuilder: (context) => const CircularProgressIndicator(),
///   errorBuilder: (context, error) => Text('Error: $error'),
///   builder: (context, viewModel) {
///     return MyContent(viewModel: viewModel);
///   },
/// )
/// ```
class ViewModelConsumer<T extends BaseViewModel> extends StatelessWidget {
  const ViewModelConsumer({
    super.key,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.child,
  });

  /// Builder for the main content when ViewModel is ready.
  final Widget Function(BuildContext context, T viewModel, Widget? child)
      builder;

  /// Builder for the loading state.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for the error state.
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Optional child widget passed to the builder.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final viewModel = ViewModelProvider.of<T>(context);

    // Show loading state
    if (!viewModel.isInitialized || viewModel.isLoading) {
      return loadingBuilder?.call(context) ?? const SizedBox.shrink();
    }

    // Show error state
    if (viewModel.hasError) {
      return errorBuilder?.call(context, viewModel.errorMessage!) ??
          const SizedBox.shrink();
    }

    // Show main content
    return builder(context, viewModel, child);
  }
}

/// A widget that listens to ViewModel changes and performs side effects.
///
/// Use this when you need to perform actions (navigation, showing dialogs)
/// in response to ViewModel state changes without rebuilding widgets.
///
/// Usage:
/// ```dart
/// ViewModelListener<MyViewModel>(
///   listener: (context, viewModel) {
///     if (viewModel.shouldNavigate) {
///       Navigator.of(context).push(...);
///     }
///   },
///   child: MyContent(),
/// )
/// ```
class ViewModelListener<T extends BaseViewModel> extends StatefulWidget {
  const ViewModelListener({
    super.key,
    required this.listener,
    required this.child,
    this.listenWhen,
  });

  /// Called when the ViewModel notifies listeners.
  final void Function(BuildContext context, T viewModel) listener;

  /// The child widget.
  final Widget child;

  /// Optional condition to determine if listener should be called.
  final bool Function(T viewModel)? listenWhen;

  @override
  State<ViewModelListener<T>> createState() => _ViewModelListenerState<T>();
}

class _ViewModelListenerState<T extends BaseViewModel>
    extends State<ViewModelListener<T>> {
  T? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribe();
  }

  void _subscribe() {
    final newViewModel = ViewModelProvider.of<T>(context);

    if (_viewModel != newViewModel) {
      _viewModel?.removeListener(_onViewModelChanged);
      _viewModel = newViewModel;
      _viewModel!.addListener(_onViewModelChanged);
    }
  }

  void _onViewModelChanged() {
    if (widget.listenWhen == null || widget.listenWhen!(_viewModel!)) {
      widget.listener(context, _viewModel!);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
