import 'package:flutter/material.dart';
import '../../design/design_system.dart';

/// A search widget for filtering BLE devices in the AppBar.
///
/// Provides a collapsible search interface that can be expanded/collapsed
/// via an icon button.
class DeviceSearchWidget extends StatefulWidget {
  const DeviceSearchWidget({
    super.key,
    required this.onSearchChanged,
    this.onSearchClosed,
    this.hintText = 'Search devices...',
  });

  /// Callback when search text changes.
  final ValueChanged<String> onSearchChanged;

  /// Callback when search is closed.
  final VoidCallback? onSearchClosed;

  /// Placeholder text for the search field.
  final String hintText;

  @override
  State<DeviceSearchWidget> createState() => _DeviceSearchWidgetState();
}

class _DeviceSearchWidgetState extends State<DeviceSearchWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignTokens.durationNormal,
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _controller.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    widget.onSearchChanged(_controller.text);
  }

  void _toggleSearch() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
      // Request focus after animation starts
      Future.delayed(const Duration(milliseconds: 100), () {
        _focusNode.requestFocus();
      });
    } else {
      _animationController.reverse();
      _controller.clear();
      widget.onSearchClosed?.call();
    }
  }

  void _clearSearch() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _widthAnimation,
          builder: (context, child) {
            return SizedBox(
              width: _widthAnimation.value * 200,
              child: _widthAnimation.value > 0.1
                  ? _buildSearchField()
                  : const SizedBox.shrink(),
            );
          },
        ),
        IconButton(
          icon: AnimatedSwitcher(
            duration: DesignTokens.durationFast,
            child: Icon(
              _isExpanded ? Icons.close : Icons.search,
              key: ValueKey(_isExpanded),
            ),
          ),
          onPressed: _toggleSearch,
          tooltip: _isExpanded ? 'Close Search' : 'Search Devices',
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Opacity(
      opacity: _widthAnimation.value,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor(context),
          borderRadius: DesignTokens.borderRadiusFull,
          border: Border.all(color: AppColors.borderColor(context)),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          style: AppTextStyles.bodyMedium(context),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: AppTextStyles.bodyMedium(context).copyWith(
              color: AppColors.textTertiary(context),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingM,
              vertical: DesignTokens.spacingS,
            ),
            border: InputBorder.none,
            isDense: true,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      size: DesignTokens.iconXS,
                      color: AppColors.textSecondary(context),
                    ),
                    onPressed: _clearSearch,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// A simpler inline search bar for device filtering.
///
/// Used in control panel or header areas where space allows.
class DeviceSearchBar extends StatelessWidget {
  const DeviceSearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    this.onClear,
    this.hintText = 'Search by name or ID...',
    this.enabled = true,
  });

  /// Text controller for the search field.
  final TextEditingController controller;

  /// Callback when search text changes.
  final ValueChanged<String> onSearchChanged;

  /// Callback when clear button is pressed.
  final VoidCallback? onClear;

  /// Placeholder text.
  final String hintText;

  /// Whether the search bar is enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onSearchChanged,
      style: AppTextStyles.bodyMedium(context),
      decoration: AppInputStyles.search(
        context,
        hintText: hintText,
        onClear: controller.text.isNotEmpty
            ? () {
                controller.clear();
                onSearchChanged('');
                onClear?.call();
              }
            : null,
      ),
    );
  }
}

/// Extension for filtering device lists by search query.
extension DeviceSearchExtension<T> on List<T> {
  /// Filter devices by search query matching name or ID.
  ///
  /// [query] - The search string to match against
  /// [getName] - Function to extract name from device
  /// [getId] - Function to extract ID from device
  List<T> filterBySearch(
    String query, {
    required String Function(T) getName,
    required String Function(T) getId,
  }) {
    if (query.isEmpty) return this;

    final lowerQuery = query.toLowerCase();
    return where((device) {
      final name = getName(device).toLowerCase();
      final id = getId(device).toLowerCase();
      return name.contains(lowerQuery) || id.contains(lowerQuery);
    }).toList();
  }
}
