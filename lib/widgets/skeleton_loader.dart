import 'package:flutter/material.dart';
import '../design/design_system.dart';
import '../utils/accessibility_utils.dart';

/// A shimmer effect widget for loading states.
///
/// Creates a subtle animated gradient that moves across the widget
/// to indicate content is loading.
///
/// Example:
/// ```dart
/// ShimmerEffect(
///   child: Container(
///     width: 200,
///     height: 20,
///     decoration: BoxDecoration(
///       color: Colors.grey,
///       borderRadius: BorderRadius.circular(4),
///     ),
///   ),
/// )
/// ```
class ShimmerEffect extends StatefulWidget {
  /// The child widget to apply shimmer effect to
  final Widget child;

  /// Duration of one shimmer animation cycle
  final Duration duration;

  /// Base color for the shimmer (typically a grey)
  final Color? baseColor;

  /// Highlight color for the shimmer (typically a lighter grey)
  final Color? highlightColor;

  /// Whether the shimmer is currently active
  final bool isLoading;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
    this.isLoading = true,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
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
    // Skip shimmer animation for reduced motion preference
    if (AccessibilityUtils.prefersReducedMotion(context) || !widget.isLoading) {
      return widget.child;
    }

    final baseColor = widget.baseColor ?? AppColors.shimmerBase(context);
    final highlightColor =
        widget.highlightColor ?? AppColors.shimmerHighlight(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// A skeleton placeholder widget for loading states.
///
/// Displays a grey placeholder with optional shimmer animation.
///
/// Example:
/// ```dart
/// SkeletonBox(
///   width: 200,
///   height: 20,
/// )
/// ```
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isLoading;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      isLoading: isLoading,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase(context),
          borderRadius: borderRadius ?? DesignTokens.borderRadiusS,
        ),
      ),
    );
  }
}

/// A skeleton placeholder for text lines.
///
/// Example:
/// ```dart
/// SkeletonText(
///   lines: 3,
///   lineHeight: 16,
/// )
/// ```
class SkeletonText extends StatelessWidget {
  /// Number of lines to show
  final int lines;

  /// Height of each line
  final double lineHeight;

  /// Spacing between lines
  final double lineSpacing;

  /// Width of the last line (as a fraction of full width)
  final double lastLineWidth;

  /// Whether currently loading
  final bool isLoading;

  const SkeletonText({
    super.key,
    this.lines = 3,
    this.lineHeight = 14,
    this.lineSpacing = 8,
    this.lastLineWidth = 0.7,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(lines, (index) {
        final isLastLine = index == lines - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? lineSpacing : 0),
          child: FractionallySizedBox(
            widthFactor: isLastLine ? lastLineWidth : 1.0,
            child: SkeletonBox(
              height: lineHeight,
              isLoading: isLoading,
            ),
          ),
        );
      }),
    );
  }
}

/// A skeleton placeholder for circular avatars.
///
/// Example:
/// ```dart
/// SkeletonCircle(radius: 24)
/// ```
class SkeletonCircle extends StatelessWidget {
  final double radius;
  final bool isLoading;

  const SkeletonCircle({
    super.key,
    this.radius = 24,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      isLoading: isLoading,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: AppColors.shimmerBase(context),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// A skeleton placeholder for BLE device list items.
///
/// Mimics the layout of DeviceListWidget items.
class SkeletonDeviceCard extends StatelessWidget {
  final bool isLoading;

  const SkeletonDeviceCard({
    super.key,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingM,
        vertical: DesignTokens.spacingXS + 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: DesignTokens.borderRadiusL,
        boxShadow: DesignTokens.cardShadow(context),
      ),
      child: Padding(
        padding: DesignTokens.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon and name
            Row(
              children: [
                SkeletonBox(
                  width: 40,
                  height: 40,
                  borderRadius: DesignTokens.borderRadiusS,
                  isLoading: isLoading,
                ),
                SizedBox(width: DesignTokens.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(
                        width: 120,
                        height: 16,
                        isLoading: isLoading,
                      ),
                      SizedBox(height: DesignTokens.spacingXS),
                      SkeletonBox(
                        width: 160,
                        height: 12,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
                // Signal strength indicator
                SkeletonBox(
                  width: 30,
                  height: 20,
                  isLoading: isLoading,
                ),
              ],
            ),
            SizedBox(height: DesignTokens.spacingSM),
            // Info rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 40, height: 12, isLoading: isLoading),
                SkeletonBox(width: 60, height: 12, isLoading: isLoading),
              ],
            ),
            SizedBox(height: DesignTokens.spacingXS),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 50, height: 12, isLoading: isLoading),
                SkeletonBox(width: 80, height: 12, isLoading: isLoading),
              ],
            ),
            SizedBox(height: DesignTokens.spacingM),
            // Action buttons
            Row(
              children: [
                SkeletonCircle(radius: 16, isLoading: isLoading),
                const Spacer(),
                SkeletonBox(
                  width: 100,
                  height: 36,
                  borderRadius: DesignTokens.borderRadiusS,
                  isLoading: isLoading,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A skeleton list that shows multiple placeholder cards.
///
/// Example:
/// ```dart
/// SkeletonDeviceList(itemCount: 5)
/// ```
class SkeletonDeviceList extends StatelessWidget {
  final int itemCount;
  final bool isLoading;

  const SkeletonDeviceList({
    super.key,
    this.itemCount = 3,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return SkeletonDeviceCard(isLoading: isLoading);
      },
    );
  }
}

/// A skeleton placeholder for message bubbles in command interface.
class SkeletonMessageBubble extends StatelessWidget {
  final bool isCommand;
  final bool isLoading;

  const SkeletonMessageBubble({
    super.key,
    this.isCommand = false,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCommand ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingM,
          vertical: DesignTokens.spacingXS,
        ),
        padding: DesignTokens.paddingM,
        decoration: BoxDecoration(
          color: isCommand
              ? AppColors.shimmerBase(context).withValues(alpha: 0.7)
              : AppColors.shimmerBase(context),
          borderRadius: DesignTokens.borderRadiusL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonText(
              lines: isCommand ? 1 : 2,
              lineHeight: 14,
              lastLineWidth: 0.6,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

/// A skeleton placeholder for stats or info cards.
class SkeletonInfoCard extends StatelessWidget {
  final double? width;
  final double height;
  final bool isLoading;

  const SkeletonInfoCard({
    super.key,
    this.width,
    this.height = 80,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: DesignTokens.borderRadiusM,
        boxShadow: DesignTokens.cardShadow(context),
      ),
      padding: DesignTokens.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SkeletonBox(
            width: 60,
            height: 12,
            isLoading: isLoading,
          ),
          SizedBox(height: DesignTokens.spacingS),
          SkeletonBox(
            width: 80,
            height: 24,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}
