import 'package:flutter/material.dart';
import '../../design/design_system.dart';

/// A search bar widget for searching device commands.
///
/// Provides a text input with search icon, clear button, and optional hint text.
class CommandSearchBar extends StatefulWidget {
  /// Callback when the search query changes.
  final ValueChanged<String>? onChanged;

  /// Callback when the search is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Hint text to display when the input is empty.
  final String hintText;

  /// Whether the search bar is enabled.
  final bool enabled;

  /// Whether to autofocus the search bar.
  final bool autofocus;

  /// Optional initial search value.
  final String? initialValue;

  const CommandSearchBar({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.hintText = '搜尋指令...',
    this.enabled = true,
    this.autofocus = false,
    this.initialValue,
  });

  @override
  State<CommandSearchBar> createState() => _CommandSearchBarState();
}

class _CommandSearchBarState extends State<CommandSearchBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: DesignTokens.borderRadiusFull,
        border: Border.all(
          color: _focusNode.hasFocus
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Search icon
          Padding(
            padding: EdgeInsets.only(left: DesignTokens.spacingSM),
            child: Icon(
              Icons.search,
              size: DesignTokens.iconS,
              color: widget.enabled
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface.withValues(alpha: DesignTokens.opacityDisabled),
            ),
          ),

          // Text input
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(
                fontSize: DesignTokens.fontM,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: DesignTokens.fontM,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacingS,
                  vertical: DesignTokens.spacingSM,
                ),
              ),
            ),
          ),

          // Clear button
          if (_hasText)
            IconButton(
              onPressed: _clearSearch,
              icon: Icon(
                Icons.clear,
                size: DesignTokens.iconS,
                color: colorScheme.onSurfaceVariant,
              ),
              splashRadius: 20,
              tooltip: '清除搜尋',
            )
          else
            SizedBox(width: DesignTokens.spacingSM),
        ],
      ),
    );
  }
}

/// A minimal search bar variant for compact spaces.
class CompactCommandSearchBar extends StatelessWidget {
  /// Callback when the search query changes.
  final ValueChanged<String>? onChanged;

  /// Hint text to display when the input is empty.
  final String hintText;

  /// Whether the search bar is enabled.
  final bool enabled;

  const CompactCommandSearchBar({
    super.key,
    this.onChanged,
    this.hintText = '搜尋...',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: CommandSearchBar(
        onChanged: onChanged,
        hintText: hintText,
        enabled: enabled,
      ),
    );
  }
}
