import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A focus management system for keyboard navigation.
///
/// Provides utilities for managing focus traversal, keyboard shortcuts,
/// and focus-related accessibility features.
///
/// Example:
/// ```dart
/// FocusableListView(
///   itemCount: items.length,
///   itemBuilder: (context, index) => ListTile(...),
///   onItemSelected: (index) => selectItem(index),
/// )
/// ```

/// A focusable widget wrapper that handles keyboard navigation.
///
/// Wraps any widget to make it focusable with keyboard navigation support.
class FocusableWidget extends StatefulWidget {
  /// The child widget to make focusable
  final Widget child;

  /// Called when the widget receives focus
  final VoidCallback? onFocus;

  /// Called when the widget loses focus
  final VoidCallback? onBlur;

  /// Called when Enter or Space is pressed while focused
  final VoidCallback? onActivate;

  /// Whether this widget should be focusable
  final bool canRequestFocus;

  /// Whether to skip this widget in focus traversal
  final bool skipTraversal;

  /// Optional focus node for manual focus management
  final FocusNode? focusNode;

  /// Whether to show focus indicator
  final bool showFocusIndicator;

  /// Focus indicator color
  final Color? focusIndicatorColor;

  /// Focus indicator width
  final double focusIndicatorWidth;

  /// Focus indicator border radius
  final BorderRadius? focusIndicatorRadius;

  const FocusableWidget({
    super.key,
    required this.child,
    this.onFocus,
    this.onBlur,
    this.onActivate,
    this.canRequestFocus = true,
    this.skipTraversal = false,
    this.focusNode,
    this.showFocusIndicator = true,
    this.focusIndicatorColor,
    this.focusIndicatorWidth = 2.0,
    this.focusIndicatorRadius,
  });

  @override
  State<FocusableWidget> createState() => _FocusableWidgetState();
}

class _FocusableWidgetState extends State<FocusableWidget> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus != _hasFocus) {
      setState(() => _hasFocus = hasFocus);
      if (hasFocus) {
        widget.onFocus?.call();
      } else {
        widget.onBlur?.call();
      }
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle Enter and Space for activation
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      widget.onActivate?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = widget.focusIndicatorColor ??
        Theme.of(context).colorScheme.primary;
    final radius = widget.focusIndicatorRadius ?? BorderRadius.circular(4);

    return Focus(
      focusNode: _focusNode,
      canRequestFocus: widget.canRequestFocus,
      skipTraversal: widget.skipTraversal,
      onKeyEvent: _handleKeyEvent,
      child: Builder(
        builder: (context) {
          if (!widget.showFocusIndicator || !_hasFocus) {
            return widget.child;
          }

          return Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: focusColor,
                width: widget.focusIndicatorWidth,
              ),
            ),
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// A focus traversal group that manages focus order.
///
/// Use this to create logical focus groups in your UI.
class FocusGroup extends StatelessWidget {
  /// The child widgets in this focus group
  final Widget child;

  /// Policy for focus traversal order
  final FocusTraversalPolicy? policy;

  /// Whether this group should be skipped entirely in traversal
  final bool skipTraversal;

  const FocusGroup({
    super.key,
    required this.child,
    this.policy,
    this.skipTraversal = false,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: policy ?? OrderedTraversalPolicy(),
      child: skipTraversal
          ? ExcludeFocus(child: child)
          : child,
    );
  }
}

/// A focusable list view with keyboard navigation.
///
/// Supports:
/// - Arrow key navigation between items
/// - Enter/Space to select
/// - Home/End to jump to first/last item
/// - Page Up/Down for larger jumps
class FocusableListView extends StatefulWidget {
  /// Number of items in the list
  final int itemCount;

  /// Builder for list items
  final Widget Function(BuildContext, int, bool) itemBuilder;

  /// Called when an item is selected (Enter/Space)
  final void Function(int)? onItemSelected;

  /// Called when the focused item changes
  final void Function(int)? onFocusChanged;

  /// Initial focused index
  final int initialFocusIndex;

  /// Scroll controller for the list
  final ScrollController? scrollController;

  /// List padding
  final EdgeInsets? padding;

  /// Whether the list is scrollable
  final ScrollPhysics? physics;

  const FocusableListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.onItemSelected,
    this.onFocusChanged,
    this.initialFocusIndex = 0,
    this.scrollController,
    this.padding,
    this.physics,
  });

  @override
  State<FocusableListView> createState() => _FocusableListViewState();
}

class _FocusableListViewState extends State<FocusableListView> {
  late int _focusedIndex;
  late ScrollController _scrollController;
  late FocusNode _focusNode;
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _focusedIndex = widget.initialFocusIndex;
    _scrollController = widget.scrollController ?? ScrollController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _moveFocus(int delta) {
    final newIndex = (_focusedIndex + delta).clamp(0, widget.itemCount - 1);
    if (newIndex != _focusedIndex) {
      setState(() => _focusedIndex = newIndex);
      widget.onFocusChanged?.call(newIndex);
      _scrollToIndex(newIndex);
    }
  }

  void _jumpToIndex(int index) {
    final clampedIndex = index.clamp(0, widget.itemCount - 1);
    if (clampedIndex != _focusedIndex) {
      setState(() => _focusedIndex = clampedIndex);
      widget.onFocusChanged?.call(clampedIndex);
      _scrollToIndex(clampedIndex);
    }
  }

  void _scrollToIndex(int index) {
    final key = _itemKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _moveFocus(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _moveFocus(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageUp:
        _moveFocus(-10);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.pageDown:
        _moveFocus(10);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        _jumpToIndex(0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _jumpToIndex(widget.itemCount - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
        widget.onItemSelected?.call(_focusedIndex);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics,
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          _itemKeys[index] ??= GlobalKey();
          final isFocused = index == _focusedIndex;

          return GestureDetector(
            onTap: () {
              setState(() => _focusedIndex = index);
              widget.onItemSelected?.call(index);
            },
            child: Container(
              key: _itemKeys[index],
              child: widget.itemBuilder(context, index, isFocused),
            ),
          );
        },
      ),
    );
  }
}

/// A keyboard shortcut handler for common actions.
///
/// Wraps a widget subtree to handle keyboard shortcuts.
class KeyboardShortcuts extends StatelessWidget {
  /// The child widget tree
  final Widget child;

  /// Map of shortcuts to their actions
  final Map<ShortcutActivator, VoidCallback> shortcuts;

  /// Whether to auto-focus this widget
  final bool autofocus;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    required this.shortcuts,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      autofocus: autofocus,
      shortcuts: {
        for (final entry in shortcuts.entries)
          entry.key: VoidCallbackIntent(entry.value),
      },
      actions: {
        VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
          onInvoke: (intent) => intent.callback(),
        ),
      },
      child: child,
    );
  }
}

/// An intent for void callbacks.
class VoidCallbackIntent extends Intent {
  final VoidCallback callback;
  const VoidCallbackIntent(this.callback);
}

/// Common keyboard shortcut definitions.
class AppShortcuts {
  AppShortcuts._();

  // Navigation shortcuts
  static const escape = SingleActivator(LogicalKeyboardKey.escape);
  static const enter = SingleActivator(LogicalKeyboardKey.enter);
  static const space = SingleActivator(LogicalKeyboardKey.space);
  static const tab = SingleActivator(LogicalKeyboardKey.tab);
  static const shiftTab = SingleActivator(
    LogicalKeyboardKey.tab,
    shift: true,
  );

  // Arrow key navigation
  static const arrowUp = SingleActivator(LogicalKeyboardKey.arrowUp);
  static const arrowDown = SingleActivator(LogicalKeyboardKey.arrowDown);
  static const arrowLeft = SingleActivator(LogicalKeyboardKey.arrowLeft);
  static const arrowRight = SingleActivator(LogicalKeyboardKey.arrowRight);

  // Common actions
  static const ctrlS = SingleActivator(
    LogicalKeyboardKey.keyS,
    control: true,
  );
  static const ctrlF = SingleActivator(
    LogicalKeyboardKey.keyF,
    control: true,
  );
  static const ctrlR = SingleActivator(
    LogicalKeyboardKey.keyR,
    control: true,
  );
  static const ctrlEnter = SingleActivator(
    LogicalKeyboardKey.enter,
    control: true,
  );

  // Mac-specific (meta key)
  static const cmdS = SingleActivator(
    LogicalKeyboardKey.keyS,
    meta: true,
  );
  static const cmdF = SingleActivator(
    LogicalKeyboardKey.keyF,
    meta: true,
  );
  static const cmdR = SingleActivator(
    LogicalKeyboardKey.keyR,
    meta: true,
  );
  static const cmdEnter = SingleActivator(
    LogicalKeyboardKey.enter,
    meta: true,
  );

  // Delete actions
  static const delete = SingleActivator(LogicalKeyboardKey.delete);
  static const backspace = SingleActivator(LogicalKeyboardKey.backspace);

  // Jump navigation
  static const home = SingleActivator(LogicalKeyboardKey.home);
  static const end = SingleActivator(LogicalKeyboardKey.end);
  static const pageUp = SingleActivator(LogicalKeyboardKey.pageUp);
  static const pageDown = SingleActivator(LogicalKeyboardKey.pageDown);
}

/// A text field with command history navigation support.
///
/// Supports:
/// - Up/Down arrows to navigate command history
/// - Enter to submit
/// - Escape to clear or cancel
class CommandTextField extends StatefulWidget {
  /// Controller for the text field
  final TextEditingController controller;

  /// Focus node for the text field
  final FocusNode? focusNode;

  /// Command history list
  final List<String> history;

  /// Called when Enter is pressed
  final VoidCallback? onSubmit;

  /// Called when Escape is pressed
  final VoidCallback? onCancel;

  /// Called when history navigation changes the text
  final void Function(String)? onHistoryNavigation;

  /// Input decoration
  final InputDecoration? decoration;

  /// Whether the field is enabled
  final bool enabled;

  /// Max lines for the text field
  final int maxLines;

  /// Text input action
  final TextInputAction textInputAction;

  const CommandTextField({
    super.key,
    required this.controller,
    required this.history,
    this.focusNode,
    this.onSubmit,
    this.onCancel,
    this.onHistoryNavigation,
    this.decoration,
    this.enabled = true,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.send,
  });

  @override
  State<CommandTextField> createState() => _CommandTextFieldState();
}

class _CommandTextFieldState extends State<CommandTextField> {
  late FocusNode _focusNode;
  int _historyIndex = -1;
  String _savedInput = '';

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(CommandTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset history index when history changes
    if (widget.history != oldWidget.history) {
      _historyIndex = -1;
    }
  }

  void _navigateHistory(int delta) {
    if (widget.history.isEmpty) return;

    // Save current input when starting to navigate
    if (_historyIndex == -1 && delta < 0) {
      _savedInput = widget.controller.text;
    }

    final newIndex = _historyIndex + delta;

    if (newIndex < -1) return;
    if (newIndex >= widget.history.length) return;

    setState(() => _historyIndex = newIndex);

    if (_historyIndex == -1) {
      // Return to saved input
      widget.controller.text = _savedInput;
    } else {
      // Navigate history (newest first)
      final historyItem = widget.history[widget.history.length - 1 - _historyIndex];
      widget.controller.text = historyItem;
    }

    // Move cursor to end
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );

    widget.onHistoryNavigation?.call(widget.controller.text);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _navigateHistory(-1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        _navigateHistory(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
        if (widget.maxLines == 1) {
          widget.onSubmit?.call();
          _historyIndex = -1;
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.escape:
        if (widget.controller.text.isNotEmpty) {
          widget.controller.clear();
          _historyIndex = -1;
          return KeyEventResult.handled;
        }
        widget.onCancel?.call();
        return KeyEventResult.handled;
      default:
        // Reset history index on any other key press
        if (_historyIndex != -1) {
          _historyIndex = -1;
        }
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: TextField(
        controller: widget.controller,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        textInputAction: widget.textInputAction,
        decoration: widget.decoration,
        onSubmitted: widget.maxLines == 1
            ? (_) {
                widget.onSubmit?.call();
                _historyIndex = -1;
              }
            : null,
      ),
    );
  }
}

/// A focus highlight wrapper that shows visual focus indicator.
class FocusHighlight extends StatelessWidget {
  /// The child widget
  final Widget child;

  /// Whether currently focused
  final bool isFocused;

  /// Focus indicator color
  final Color? color;

  /// Border radius for the indicator
  final BorderRadius? borderRadius;

  /// Padding between indicator and child
  final EdgeInsets padding;

  const FocusHighlight({
    super.key,
    required this.child,
    required this.isFocused,
    this.color,
    this.borderRadius,
    this.padding = const EdgeInsets.all(2),
  });

  @override
  Widget build(BuildContext context) {
    if (!isFocused) return child;

    final focusColor = color ?? Theme.of(context).colorScheme.primary;
    final radius = borderRadius ?? BorderRadius.circular(4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: focusColor,
          width: 2,
        ),
      ),
      child: child,
    );
  }
}

/// Extension methods for FocusNode.
extension FocusNodeExtensions on FocusNode {
  /// Request focus with optional scroll to visible
  void requestFocusAndScroll(BuildContext context) {
    requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 200),
        );
      }
    });
  }
}

/// A trap focus widget that keeps focus within its children.
///
/// Useful for modal dialogs and overlays.
class FocusTrap extends StatelessWidget {
  /// The child widget tree
  final Widget child;

  /// Whether to auto-focus the first focusable child
  final bool autofocus;

  const FocusTrap({
    super.key,
    required this.child,
    this.autofocus = true,
  });

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: autofocus,
      child: child,
    );
  }
}
