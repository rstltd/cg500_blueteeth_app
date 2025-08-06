import 'package:flutter/material.dart';
import '../services/animation_service.dart';

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
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: widget.isScanning ? 2 : 6,
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

/// Animated list item with staggered entrance
class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Curve curve;

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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
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
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Staggered entrance
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}