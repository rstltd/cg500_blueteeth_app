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
