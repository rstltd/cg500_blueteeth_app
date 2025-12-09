import 'package:flutter/material.dart';
import '../../design/design_system.dart';
import '../../services/animation_service.dart';
import '../../utils/accessibility_utils.dart';

/// Animated scanning button with radar animation
class AnimatedScanButton extends StatefulWidget {
  final bool isScanning;
  final VoidCallback? onPressed;
  final String text;
  final String? scanningText;

  const AnimatedScanButton({
    super.key,
    required this.isScanning,
    required this.onPressed,
    required this.text,
    this.scanningText,
  });

  @override
  State<AnimatedScanButton> createState() => _AnimatedScanButtonState();
}

class _AnimatedScanButtonState extends State<AnimatedScanButton>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      duration: AnimationService.scanningDuration,
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    if (widget.isScanning) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(AnimatedScanButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    _radarController.repeat();
    _pulseController.repeat(reverse: true);
  }

  void _stopAnimations() {
    _radarController.stop();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AnimationService.defaultDuration,
      child: ElevatedButton.icon(
        onPressed: widget.onPressed,
        icon: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isScanning) ...[
              // Radar animation
              SizedBox(
                width: 24,
                height: 24,
                child: AnimationService.createScanningRadar(
                  controller: _radarController,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ] else ...[
              // Static radar icon
              const Icon(Icons.radar),
            ],
          ],
        ),
        label: AnimationService.createPulseAnimation(
          controller: _pulseController,
          child: Text(
            widget.isScanning 
                ? (widget.scanningText ?? 'Scanning...') 
                : widget.text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isScanning
              ? Colors.red.shade600
              : Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: DesignTokens.spacingM),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusM,
          ),
          elevation: widget.isScanning ? DesignTokens.elevationS : DesignTokens.elevationL,
        ),
      ),
    );
  }
}

/// Animated device card with entrance animation
class AnimatedDeviceCard extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedDeviceCard({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedDeviceCard> createState() => _AnimatedDeviceCardState();
}

class _AnimatedDeviceCardState extends State<AnimatedDeviceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationService.defaultDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Staggered entrance animation
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Animated connection status indicator
class AnimatedConnectionStatus extends StatefulWidget {
  final bool isConnected;
  final Widget child;

  const AnimatedConnectionStatus({
    super.key,
    required this.isConnected,
    required this.child,
  });

  @override
  State<AnimatedConnectionStatus> createState() => _AnimatedConnectionStatusState();
}

class _AnimatedConnectionStatusState extends State<AnimatedConnectionStatus>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    if (widget.isConnected) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(AnimatedConnectionStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    _breathingController.repeat(reverse: true);
    _pulseController.repeat();
  }

  void _stopAnimations() {
    _breathingController.stop();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimationService.createConnectionStatusAnimation(
      controller: _breathingController,
      isConnected: widget.isConnected,
      child: widget.child,
    );
  }
}

/// Animated floating action button with scale effect
class AnimatedFloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? tooltip;
  final Color? backgroundColor;

  const AnimatedFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.backgroundColor,
  });

  @override
  State<AnimatedFloatingActionButton> createState() => _AnimatedFloatingActionButtonState();
}

class _AnimatedFloatingActionButtonState extends State<AnimatedFloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AnimationService.fastDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
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

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FloatingActionButton(
              onPressed: null, // Handle by GestureDetector
              backgroundColor: widget.backgroundColor,
              tooltip: widget.tooltip,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Success/Error feedback animation widget
class AnimatedFeedback extends StatefulWidget {
  final bool showSuccess;
  final bool showError;
  final Duration duration;
  final VoidCallback? onComplete;

  const AnimatedFeedback({
    super.key,
    this.showSuccess = false,
    this.showError = false,
    this.duration = const Duration(milliseconds: 1000),
    this.onComplete,
  });

  @override
  State<AnimatedFeedback> createState() => _AnimatedFeedbackState();
}

class _AnimatedFeedbackState extends State<AnimatedFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    if (widget.showSuccess || widget.showError) {
      _controller.forward().then((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.showSuccess || widget.showError) &&
        !(oldWidget.showSuccess || oldWidget.showError)) {
      _controller.reset();
      _controller.forward().then((_) {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showSuccess && !widget.showError) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Transform.scale(
            scale: _controller.value,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.showSuccess ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (widget.showSuccess ? Colors.green : Colors.red)
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: widget.showSuccess
                  ? AnimationService.createSuccessAnimation(
                      controller: _controller,
                      color: Colors.white,
                    )
                  : AnimationService.createErrorAnimation(
                      controller: _controller,
                      color: Colors.white,
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// Animated list item with staggered entrance and reduced motion support.
///
/// Features:
/// - Respects user's "Reduce motion" accessibility setting
/// - Limits animation delay for large lists (performance optimization)
/// - Uses efficient RepaintBoundary for list items
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Curve curve;

  /// Maximum index to apply staggered animation (for performance)
  static const int maxAnimatedIndex = 20;

  /// Maximum delay to prevent long waits in large lists
  static const Duration maxTotalDelay = Duration(milliseconds: 1000);

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 50),
    this.curve = Curves.easeOutQuart,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400), // Shorter for performance
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.8, curve: widget.curve),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.2, 0.0), // Reduced slide distance
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = AccessibilityUtils.prefersReducedMotion(context);
    _startAnimation();
  }

  void _startAnimation() {
    // Skip animation if reduced motion is preferred
    if (_reducedMotion) {
      _controller.value = 1.0;
      return;
    }

    // Skip animation for items beyond the threshold (performance)
    if (widget.index >= AnimatedListItem.maxAnimatedIndex) {
      _controller.value = 1.0;
      return;
    }

    // Calculate staggered delay with cap for performance
    final calculatedDelay = widget.delay * widget.index;
    final effectiveDelay = calculatedDelay > AnimatedListItem.maxTotalDelay
        ? AnimatedListItem.maxTotalDelay
        : calculatedDelay;

    Future.delayed(effectiveDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use RepaintBoundary to optimize list item rendering
    return RepaintBoundary(
      child: _reducedMotion
          ? widget.child // No animation for reduced motion
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: widget.child,
              ),
            ),
    );
  }
}

/// Animated pulse effect for newly discovered devices.
///
/// Shows a brief glowing pulse effect when a device is first discovered.
/// The animation automatically completes and does not repeat.
class NewDevicePulseAnimation extends StatefulWidget {
  final Widget child;
  final bool isNew;
  final Duration duration;
  final Color? pulseColor;

  const NewDevicePulseAnimation({
    super.key,
    required this.child,
    this.isNew = false,
    this.duration = const Duration(milliseconds: 1500),
    this.pulseColor,
  });

  @override
  State<NewDevicePulseAnimation> createState() => _NewDevicePulseAnimationState();
}

class _NewDevicePulseAnimationState extends State<NewDevicePulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_controller);
    // Note: Don't call _startAnimation() here - context is not available yet
    // Animation will be started in didChangeDependencies() instead
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start animation here after dependencies (including MediaQuery) are available
    if (widget.isNew && !_hasPlayed) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(NewDevicePulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNew && !oldWidget.isNew && !_hasPlayed) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    // Check for reduced motion preference
    if (mounted && !AccessibilityUtils.prefersReducedMotion(context)) {
      _hasPlayed = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isNew || _controller.status == AnimationStatus.dismissed) {
      return widget.child;
    }

    final pulseColor = widget.pulseColor ?? AppColors.successColor(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: DesignTokens.borderRadiusM,
              boxShadow: _glowAnimation.value > 0
                  ? [
                      BoxShadow(
                        color: pulseColor.withValues(alpha: 0.3 * _glowAnimation.value),
                        blurRadius: 12 * _glowAnimation.value,
                        spreadRadius: 2 * _glowAnimation.value,
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

/// Animated RSSI signal strength indicator with pulsing effect.
///
/// Shows an animated signal strength indicator that pulses when
/// actively receiving updates.
class AnimatedSignalStrength extends StatefulWidget {
  final int rssi;
  final bool isActive;
  final double size;

  const AnimatedSignalStrength({
    super.key,
    required this.rssi,
    this.isActive = false,
    this.size = 24,
  });

  @override
  State<AnimatedSignalStrength> createState() => _AnimatedSignalStrengthState();
}

class _AnimatedSignalStrengthState extends State<AnimatedSignalStrength>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedSignalStrength oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signalLevel = _getSignalLevel(widget.rssi);
    final color = _getSignalColor(context, signalLevel);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: widget.isActive ? _pulseAnimation.value : 1.0,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _SignalStrengthPainter(
                level: signalLevel,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }

  int _getSignalLevel(int rssi) {
    if (rssi >= -50) return 4;
    if (rssi >= -60) return 3;
    if (rssi >= -70) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }

  Color _getSignalColor(BuildContext context, int level) {
    switch (level) {
      case 4:
        return AppColors.successColor(context);
      case 3:
        return AppColors.successColor(context);
      case 2:
        return AppColors.warningColor(context);
      case 1:
        return AppColors.errorColor(context);
      default:
        return AppColors.errorColor(context);
    }
  }
}

class _SignalStrengthPainter extends CustomPainter {
  final int level;
  final Color color;

  _SignalStrengthPainter({
    required this.level,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / 5;
    final spacing = barWidth * 0.5;
    final heights = [0.25, 0.5, 0.75, 1.0];

    for (int i = 0; i < 4; i++) {
      final isActive = i < level;
      paint.color = isActive ? color : color.withValues(alpha: 0.2);

      final x = i * (barWidth + spacing) + barWidth / 2;
      final barHeight = size.height * heights[i];
      final y1 = size.height;
      final y2 = size.height - barHeight;

      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SignalStrengthPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}

/// Animated state transition wrapper for smooth content changes.
///
/// Provides smooth crossfade transitions when switching between different
/// states (e.g., loading, empty, content, error).
///
/// Example:
/// ```dart
/// AnimatedStateTransition(
///   state: isLoading ? ViewState.loading : ViewState.content,
///   loadingWidget: CircularProgressIndicator(),
///   contentWidget: MyContent(),
/// )
/// ```
class AnimatedStateTransition extends StatelessWidget {
  /// Current view state
  final ViewState state;

  /// Widget to show during loading state
  final Widget? loadingWidget;

  /// Widget to show when content is available
  final Widget? contentWidget;

  /// Widget to show when no content (empty state)
  final Widget? emptyWidget;

  /// Widget to show on error
  final Widget? errorWidget;

  /// Duration of the transition animation
  final Duration duration;

  /// Curve for the transition animation
  final Curve curve;

  /// Whether to animate the first build
  final bool animateFirstBuild;

  const AnimatedStateTransition({
    super.key,
    required this.state,
    this.loadingWidget,
    this.contentWidget,
    this.emptyWidget,
    this.errorWidget,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.animateFirstBuild = false,
  });

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AccessibilityUtils.prefersReducedMotion(context);

    Widget? currentWidget;
    switch (state) {
      case ViewState.loading:
        currentWidget = loadingWidget ?? const Center(child: CircularProgressIndicator());
        break;
      case ViewState.content:
        currentWidget = contentWidget ?? const SizedBox.shrink();
        break;
      case ViewState.empty:
        currentWidget = emptyWidget ?? const SizedBox.shrink();
        break;
      case ViewState.error:
        currentWidget = errorWidget ?? const SizedBox.shrink();
        break;
    }

    if (reducedMotion) {
      return currentWidget;
    }

    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: KeyedSubtree(
        key: ValueKey(state),
        child: currentWidget,
      ),
    );
  }
}

/// View state enumeration for AnimatedStateTransition
enum ViewState {
  loading,
  content,
  empty,
  error,
}

/// Animated content switcher with slide and fade transitions.
///
/// Smoothly transitions between different content widgets with
/// directional slide animations.
///
/// Example:
/// ```dart
/// AnimatedContentSwitcher(
///   child: currentPage,
///   direction: SlideDirection.left,
/// )
/// ```
class AnimatedContentSwitcher extends StatelessWidget {
  /// The current content widget
  final Widget child;

  /// Direction of the slide transition
  final SlideDirection direction;

  /// Duration of the transition
  final Duration duration;

  /// Animation curve
  final Curve curve;

  const AnimatedContentSwitcher({
    super.key,
    required this.child,
    this.direction = SlideDirection.fade,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AccessibilityUtils.prefersReducedMotion(context);

    if (reducedMotion || direction == SlideDirection.fade) {
      return AnimatedSwitcher(
        duration: duration,
        child: child,
      );
    }

    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        final slideAnimation = Tween<Offset>(
          begin: _getBeginOffset(),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: curve));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Offset _getBeginOffset() {
    switch (direction) {
      case SlideDirection.left:
        return const Offset(-0.2, 0);
      case SlideDirection.right:
        return const Offset(0.2, 0);
      case SlideDirection.up:
        return const Offset(0, -0.2);
      case SlideDirection.down:
        return const Offset(0, 0.2);
      case SlideDirection.fade:
        return Offset.zero;
    }
  }
}

/// Direction for slide animations
enum SlideDirection {
  left,
  right,
  up,
  down,
  fade,
}

/// Animated visibility wrapper with configurable entrance/exit animations.
///
/// Shows or hides content with smooth animations.
///
/// Example:
/// ```dart
/// AnimatedVisibilityTransition(
///   visible: showContent,
///   child: MyWidget(),
/// )
/// ```
class AnimatedVisibilityTransition extends StatefulWidget {
  /// Whether the child is visible
  final bool visible;

  /// The child widget to show/hide
  final Widget child;

  /// Duration of the animation
  final Duration duration;

  /// Animation curve
  final Curve curve;

  /// Whether to maintain state when hidden
  final bool maintainState;

  /// Whether to animate the initial build
  final bool animateInitial;

  const AnimatedVisibilityTransition({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.maintainState = false,
    this.animateInitial = true,
  });

  @override
  State<AnimatedVisibilityTransition> createState() =>
      _AnimatedVisibilityTransitionState();
}

class _AnimatedVisibilityTransitionState
    extends State<AnimatedVisibilityTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.visible) {
      if (widget.animateInitial) {
        _controller.forward();
      } else {
        _controller.value = 1.0;
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedVisibilityTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AccessibilityUtils.prefersReducedMotion(context);

    if (reducedMotion) {
      return widget.visible
          ? widget.child
          : (widget.maintainState
              ? Offstage(offstage: true, child: widget.child)
              : const SizedBox.shrink());
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.isDismissed && !widget.maintainState) {
          return const SizedBox.shrink();
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: widget.maintainState
                ? Visibility(
                    visible: !_controller.isDismissed,
                    maintainState: true,
                    child: widget.child,
                  )
                : widget.child,
          ),
        );
      },
    );
  }
}

/// Animated connection state indicator with smooth transitions.
///
/// Shows a visual indicator that smoothly transitions between
/// disconnected, connecting, and connected states.
///
/// Example:
/// ```dart
/// AnimatedConnectionStateIndicator(
///   state: ConnectionState.connected,
/// )
/// ```
class AnimatedConnectionStateIndicator extends StatefulWidget {
  /// Current connection state
  final BleConnectionState state;

  /// Size of the indicator
  final double size;

  /// Whether to show the label
  final bool showLabel;

  const AnimatedConnectionStateIndicator({
    super.key,
    required this.state,
    this.size = 12,
    this.showLabel = true,
  });

  @override
  State<AnimatedConnectionStateIndicator> createState() =>
      _AnimatedConnectionStateIndicatorState();
}

class _AnimatedConnectionStateIndicatorState
    extends State<AnimatedConnectionStateIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(AnimatedConnectionStateIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.state == BleConnectionState.connecting) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AccessibilityUtils.prefersReducedMotion(context);
    final color = _getStateColor(context);
    final label = _getStateLabel();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(
                  alpha: reducedMotion ? 1.0 : (0.5 + 0.5 * _pulseController.value),
                ),
                boxShadow: widget.state == BleConnectionState.connected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            );
          },
        ),
        if (widget.showLabel) ...[
          SizedBox(width: DesignTokens.spacingXS),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              label,
              key: ValueKey(label),
              style: AppTextStyles.caption(context).copyWith(
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _getStateColor(BuildContext context) {
    switch (widget.state) {
      case BleConnectionState.disconnected:
        return AppColors.textTertiary(context);
      case BleConnectionState.connecting:
        return AppColors.warningColor(context);
      case BleConnectionState.connected:
        return AppColors.successColor(context);
      case BleConnectionState.disconnecting:
        return AppColors.warningColor(context);
    }
  }

  String _getStateLabel() {
    switch (widget.state) {
      case BleConnectionState.disconnected:
        return 'Disconnected';
      case BleConnectionState.connecting:
        return 'Connecting...';
      case BleConnectionState.connected:
        return 'Connected';
      case BleConnectionState.disconnecting:
        return 'Disconnecting...';
    }
  }
}

/// BLE connection state for AnimatedConnectionStateIndicator
enum BleConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

/// Animated loading overlay with fade transition.
///
/// Shows a semi-transparent overlay with loading indicator that
/// smoothly fades in/out.
///
/// Example:
/// ```dart
/// Stack(
///   children: [
///     MyContent(),
///     AnimatedLoadingOverlay(
///       isLoading: isLoading,
///       message: 'Loading...',
///     ),
///   ],
/// )
/// ```
class AnimatedLoadingOverlay extends StatelessWidget {
  /// Whether the loading overlay is visible
  final bool isLoading;

  /// Optional loading message
  final String? message;

  /// Background color of the overlay
  final Color? backgroundColor;

  /// Duration of the fade animation
  final Duration duration;

  const AnimatedLoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
    this.backgroundColor,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedVisibilityTransition(
      visible: isLoading,
      duration: duration,
      animateInitial: false,
      child: ColoredBox(
        color: backgroundColor ?? AppColors.darkOverlay(context),
        child: Center(
          child: Container(
            padding: DesignTokens.paddingL,
            decoration: BoxDecoration(
              color: AppColors.cardColor(context),
              borderRadius: DesignTokens.borderRadiusL,
              boxShadow: DesignTokens.cardShadow(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryColor(context),
                  ),
                ),
                if (message != null) ...[
                  SizedBox(height: DesignTokens.spacingM),
                  Text(
                    message!,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated expand/collapse container.
///
/// Smoothly expands or collapses content with animation.
///
/// Example:
/// ```dart
/// AnimatedExpandCollapse(
///   isExpanded: showDetails,
///   child: DetailsWidget(),
/// )
/// ```
class AnimatedExpandCollapse extends StatefulWidget {
  /// Whether the content is expanded
  final bool isExpanded;

  /// The content to show/hide
  final Widget child;

  /// Duration of the animation
  final Duration duration;

  /// Animation curve
  final Curve curve;

  const AnimatedExpandCollapse({
    super.key,
    required this.isExpanded,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<AnimatedExpandCollapse> createState() => _AnimatedExpandCollapseState();
}

class _AnimatedExpandCollapseState extends State<AnimatedExpandCollapse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _heightFactor = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.7, curve: widget.curve),
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedExpandCollapse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AccessibilityUtils.prefersReducedMotion(context);

    if (reducedMotion) {
      return widget.isExpanded ? widget.child : const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _heightFactor.value,
            child: FadeTransition(
              opacity: _opacity,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// Animated counter that smoothly transitions between values.
///
/// Example:
/// ```dart
/// AnimatedCounter(
///   value: deviceCount,
///   style: AppTextStyles.headline(context),
/// )
/// ```
class AnimatedCounter extends StatelessWidget {
  /// The current value to display
  final int value;

  /// Text style for the counter
  final TextStyle? style;

  /// Duration of the animation
  final Duration duration;

  /// Prefix text before the number
  final String? prefix;

  /// Suffix text after the number
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 500),
    this.prefix,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AccessibilityUtils.prefersReducedMotion(context);
    final effectiveStyle = style ?? AppTextStyles.titleLarge(context);

    if (reducedMotion) {
      return Text(
        '${prefix ?? ''}$value${suffix ?? ''}',
        style: effectiveStyle,
      );
    }

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      builder: (context, animatedValue, child) {
        return Text(
          '${prefix ?? ''}$animatedValue${suffix ?? ''}',
          style: effectiveStyle,
        );
      },
    );
  }
}

/// A high-performance list widget that uses item recycling and
/// optimized animations for large datasets.
class PerformantAnimatedList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  const PerformantAnimatedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.controller,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final reducedMotion = AccessibilityUtils.prefersReducedMotion(context);

    return ListView.builder(
      controller: controller,
      physics: physics,
      padding: padding,
      itemCount: itemCount,
      // Use cacheExtent for smoother scrolling with large lists
      cacheExtent: 200,
      // Add semantic indexes for accessibility
      addSemanticIndexes: true,
      itemBuilder: (context, index) {
        final item = itemBuilder(context, index);

        // Skip animation wrapper for reduced motion or large lists
        if (reducedMotion || index >= AnimatedListItem.maxAnimatedIndex) {
          return RepaintBoundary(child: item);
        }

        return AnimatedListItem(
          index: index,
          child: item,
        );
      },
    );
  }
}