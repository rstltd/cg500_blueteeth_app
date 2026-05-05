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
