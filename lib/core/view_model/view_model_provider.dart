import 'package:flutter/widgets.dart';
import 'base_view_model.dart';

/// A widget that provides a ViewModel to its descendants.
///
/// ViewModelProvider handles the lifecycle of the ViewModel, including:
/// - Creating the ViewModel using the provided [create] function
/// - Initializing the ViewModel automatically
/// - Disposing the ViewModel when the widget is removed
///
/// Usage:
/// ```dart
/// ViewModelProvider<MyViewModel>(
///   create: () => MyViewModel(),
///   builder: (context, viewModel, child) {
///     return MyView(viewModel: viewModel);
///   },
/// )
/// ```
///
/// To access the ViewModel from a descendant:
/// ```dart
/// final viewModel = ViewModelProvider.of<MyViewModel>(context);
/// ```
class ViewModelProvider<T extends BaseViewModel> extends StatefulWidget {
  /// Creates a ViewModelProvider.
  ///
  /// [create] is called once to create the ViewModel.
  /// [builder] is called to build the widget tree.
  /// [child] is an optional widget that doesn't depend on the ViewModel.
  const ViewModelProvider({
    super.key,
    required this.create,
    required this.builder,
    this.child,
    this.lazy = false,
    this.onReady,
  });

  /// Factory function to create the ViewModel.
  final T Function() create;

  /// Builder function that receives the ViewModel.
  final Widget Function(BuildContext context, T viewModel, Widget? child)
      builder;

  /// Optional child widget that doesn't depend on the ViewModel.
  ///
  /// This widget won't rebuild when the ViewModel notifies listeners.
  final Widget? child;

  /// Whether to delay initialization until first access.
  ///
  /// When false (default), the ViewModel is initialized immediately.
  /// When true, initialization happens on first [of] call.
  final bool lazy;

  /// Callback when the ViewModel is ready (initialized).
  final void Function(T viewModel)? onReady;

  /// Get the ViewModel from the nearest ancestor ViewModelProvider.
  ///
  /// Throws if no ViewModelProvider of type T is found.
  static T of<T extends BaseViewModel>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_ViewModelInherited<T>>();

    if (provider == null) {
      throw FlutterError(
        'ViewModelProvider.of<$T>() called with a context that does not '
        'contain a ViewModelProvider<$T>.\n'
        'Make sure to wrap your widget tree with ViewModelProvider<$T>.',
      );
    }

    return provider.viewModel;
  }

  /// Get the ViewModel from the nearest ancestor ViewModelProvider,
  /// or null if not found.
  static T? maybeOf<T extends BaseViewModel>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<_ViewModelInherited<T>>();
    return provider?.viewModel;
  }

  /// Read the ViewModel without creating a dependency.
  ///
  /// Use this when you need to access the ViewModel but don't want
  /// to rebuild when it changes.
  static T read<T extends BaseViewModel>(BuildContext context) {
    final provider = context
        .getInheritedWidgetOfExactType<_ViewModelInherited<T>>();

    if (provider == null) {
      throw FlutterError(
        'ViewModelProvider.read<$T>() called with a context that does not '
        'contain a ViewModelProvider<$T>.',
      );
    }

    return provider.viewModel;
  }

  @override
  State<ViewModelProvider<T>> createState() => _ViewModelProviderState<T>();
}

class _ViewModelProviderState<T extends BaseViewModel>
    extends State<ViewModelProvider<T>> {
  late T _viewModel;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _viewModel = widget.create();
    _viewModel.addListener(_onViewModelChanged);

    // Set mounted state if the ViewModel supports it
    if (_viewModel is MountedAwareMixin) {
      (_viewModel as MountedAwareMixin).setMounted(true);
    }

    if (!widget.lazy) {
      _initializeViewModel();
    }
  }

  Future<void> _initializeViewModel() async {
    if (_isInitializing || _viewModel.isInitialized) return;

    _isInitializing = true;
    await _viewModel.initialize();
    _isInitializing = false;

    if (mounted && _viewModel.isInitialized) {
      widget.onReady?.call(_viewModel);
    }
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (_viewModel is MountedAwareMixin) {
      (_viewModel as MountedAwareMixin).setMounted(false);
    }
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ViewModelInherited<T>(
      viewModel: _viewModel,
      child: widget.builder(context, _viewModel, widget.child),
    );
  }
}

/// InheritedWidget that holds the ViewModel reference.
class _ViewModelInherited<T extends BaseViewModel> extends InheritedWidget {
  const _ViewModelInherited({
    required this.viewModel,
    required super.child,
  });

  final T viewModel;

  @override
  bool updateShouldNotify(_ViewModelInherited<T> oldWidget) {
    return viewModel != oldWidget.viewModel;
  }
}

/// Extension to make accessing ViewModels more convenient.
extension ViewModelContext on BuildContext {
  /// Get a ViewModel of type T from the nearest ViewModelProvider.
  T viewModel<T extends BaseViewModel>() => ViewModelProvider.of<T>(this);

  /// Get a ViewModel of type T without creating a dependency.
  T readViewModel<T extends BaseViewModel>() => ViewModelProvider.read<T>(this);

  /// Get a ViewModel of type T, or null if not found.
  T? maybeViewModel<T extends BaseViewModel>() =>
      ViewModelProvider.maybeOf<T>(this);
}
