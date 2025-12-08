import 'package:flutter/material.dart';
import '../../design/design_system.dart';

/// A consistent loading indicator used throughout the app.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size = LoadingSize.medium,
    this.color,
  });

  /// Optional message to display below the indicator.
  final String? message;

  /// Size variant of the loading indicator.
  final LoadingSize size;

  /// Optional custom color for the indicator.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final indicatorSize = _getIndicatorSize();
    final strokeWidth = _getStrokeWidth();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: indicatorSize,
            height: indicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: color != null
                  ? AlwaysStoppedAnimation<Color>(color!)
                  : null,
            ),
          ),
          if (message != null) ...[
            SizedBox(height: DesignTokens.spacingM),
            Text(
              message!,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  double _getIndicatorSize() {
    switch (size) {
      case LoadingSize.small:
        return 20.0;
      case LoadingSize.medium:
        return 36.0;
      case LoadingSize.large:
        return 48.0;
    }
  }

  double _getStrokeWidth() {
    switch (size) {
      case LoadingSize.small:
        return 2.0;
      case LoadingSize.medium:
        return 3.0;
      case LoadingSize.large:
        return 4.0;
    }
  }
}

/// Loading indicator size variants.
enum LoadingSize {
  small,
  medium,
  large,
}

/// A full-screen loading overlay.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
  });

  final String? message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ??
          AppColors.surfaceColor(context).withValues(alpha: 0.8),
      child: AppLoadingIndicator(
        message: message,
        size: LoadingSize.large,
      ),
    );
  }
}

/// A shimmer/skeleton loading placeholder.
class AppShimmerPlaceholder extends StatefulWidget {
  const AppShimmerPlaceholder({
    super.key,
    this.width,
    this.height = 16.0,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<AppShimmerPlaceholder> createState() => _AppShimmerPlaceholderState();
}

class _AppShimmerPlaceholderState extends State<AppShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? DesignTokens.borderRadiusS,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.borderColor(context),
                AppColors.cardColor(context),
                AppColors.borderColor(context),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}
