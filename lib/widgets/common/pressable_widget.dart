import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design/design_system.dart';
import '../../utils/accessibility_utils.dart';

/// A widget that provides press feedback with scale and elevation changes.
///
/// Wraps any widget to provide:
/// - Scale down animation on press
/// - Elevation change on press
/// - Optional haptic feedback
/// - Respects reduce motion accessibility setting
///
/// Example:
/// ```dart
/// PressableWidget(
///   onPressed: () => print('Pressed!'),
///   child: Container(
///     padding: DesignTokens.paddingM,
///     child: Text('Press me'),
///   ),
/// )
/// ```
class PressableWidget extends StatefulWidget {
  /// The child widget to wrap with press feedback
  final Widget child;

  /// Called when the widget is pressed
  final VoidCallback? onPressed;

  /// Called when a long press is detected
  final VoidCallback? onLongPress;

  /// Scale factor when pressed (default: 0.95 = 5% smaller)
  final double pressedScale;

  /// Elevation when not pressed (default: 0)
  final double baseElevation;

  /// Elevation when pressed (default: 2)
  final double pressedElevation;

  /// Animation duration
  final Duration duration;

  /// Whether to provide haptic feedback on press
  final bool enableHapticFeedback;

  /// Border radius for the shadow
  final BorderRadius? borderRadius;

  /// Shadow color
  final Color? shadowColor;

  const PressableWidget({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.baseElevation = 0,
    this.pressedElevation = 2,
    this.duration = const Duration(milliseconds: 100),
    this.enableHapticFeedback = true,
    this.borderRadius,
    this.shadowColor,
  });

  @override
  State<PressableWidget> createState() => _PressableWidgetState();
}

class _PressableWidgetState extends State<PressableWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.baseElevation,
      end: widget.pressedElevation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null && widget.onLongPress == null) return;

    setState(() => _isPressed = true);

    // Check for reduced motion preference
    if (!AccessibilityUtils.prefersReducedMotion(context)) {
      _controller.forward();
    }

    // Haptic feedback
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _resetState();
  }

  void _handleTapCancel() {
    _resetState();
  }

  void _resetState() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTap() {
    widget.onPressed?.call();
  }

  void _handleLongPress() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AccessibilityUtils.prefersReducedMotion(context);
    final shadowColor = widget.shadowColor ?? AppColors.shadowColor(context);
    final borderRadius = widget.borderRadius ?? DesignTokens.borderRadiusM;

    // If disabled, just return the child
    if (widget.onPressed == null && widget.onLongPress == null) {
      return widget.child;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      onLongPress: widget.onLongPress != null ? _handleLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Skip animation effects if reduced motion is preferred
          if (reducedMotion) {
            return widget.child;
          }

          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                boxShadow: _elevationAnimation.value > 0
                    ? [
                        BoxShadow(
                          color: shadowColor.withValues(
                            alpha: 0.1 * _elevationAnimation.value,
                          ),
                          blurRadius: _elevationAnimation.value * 2,
                          offset: Offset(0, _elevationAnimation.value),
                        ),
                      ]
                    : null,
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// A button with built-in press feedback animation.
///
/// Combines ElevatedButton styling with press animation effects.
///
/// Example:
/// ```dart
/// AnimatedButton(
///   onPressed: () => print('Pressed!'),
///   style: AppButtonStyles.primary(context),
///   child: Text('Submit'),
/// )
/// ```
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ButtonStyle? style;
  final bool enableHapticFeedback;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.style,
    this.enableHapticFeedback = true,
  });

  /// Creates an animated elevated button
  factory AnimatedButton.elevated({
    Key? key,
    required Widget child,
    VoidCallback? onPressed,
    VoidCallback? onLongPress,
    ButtonStyle? style,
    bool enableHapticFeedback = true,
  }) {
    return AnimatedButton(
      key: key,
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: style,
      enableHapticFeedback: enableHapticFeedback,
      child: child,
    );
  }

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHighlightChange(bool highlighted) {
    if (widget.onPressed == null) return;

    setState(() => _isPressed = highlighted);

    if (!AccessibilityUtils.prefersReducedMotion(context)) {
      if (highlighted) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }

    if (highlighted && widget.enableHapticFeedback) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AccessibilityUtils.prefersReducedMotion(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: reducedMotion ? 1.0 : _scaleAnimation.value,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            onLongPress: widget.onLongPress,
            style: widget.style,
            onHover: (hovering) {
              if (hovering && !_isPressed) {
                _handleHighlightChange(true);
              } else if (!hovering && !_isPressed) {
                _handleHighlightChange(false);
              }
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// A card with press feedback for interactive list items.
///
/// Example:
/// ```dart
/// PressableCard(
///   onPressed: () => navigateToDetails(),
///   child: ListTile(
///     title: Text('Item'),
///   ),
/// )
/// ```
class PressableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final double elevation;
  final bool enableHapticFeedback;

  const PressableCard({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.elevation = 1,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return PressableWidget(
      onPressed: onPressed,
      onLongPress: onLongPress,
      baseElevation: elevation,
      pressedElevation: elevation + 2,
      borderRadius: borderRadius ?? DesignTokens.borderRadiusM,
      enableHapticFeedback: enableHapticFeedback,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).cardColor,
          borderRadius: borderRadius ?? DesignTokens.borderRadiusM,
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: AppColors.shadowColor(context).withValues(alpha: 0.1),
                    blurRadius: elevation * 2,
                    offset: Offset(0, elevation),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? DesignTokens.borderRadiusM,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// An icon button with scale animation on press.
///
/// Example:
/// ```dart
/// AnimatedIconButton(
///   icon: Icons.favorite,
///   onPressed: () => toggleFavorite(),
///   color: Colors.red,
/// )
/// ```
class AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;
  final bool enableHapticFeedback;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24,
    this.tooltip,
    this.enableHapticFeedback = true,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onPressed == null) return;

    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    if (!AccessibilityUtils.prefersReducedMotion(context)) {
      _controller.forward(from: 0);
    }

    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AccessibilityUtils.prefersReducedMotion(context);

    Widget button = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: reducedMotion ? 1.0 : _scaleAnimation.value,
          child: IconButton(
            icon: Icon(
              widget.icon,
              color: widget.color ?? AppColors.textSecondary(context),
              size: widget.size,
            ),
            onPressed: _handleTap,
            style: AppButtonStyles.icon(context),
          ),
        );
      },
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}
