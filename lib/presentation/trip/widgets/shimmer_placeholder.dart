import 'package:flutter/material.dart';
import 'package:wandrr/presentation/app/theming/app_colors.dart';

/// A shimmer placeholder that sweeps a highlight gradient left-to-right,
/// tinted with the app's brand palette for both light and dark themes.
class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerPlaceholder({
    super.key,
    this.width = double.infinity,
    this.height = double.infinity,
    this.borderRadius,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    // Light theme: use a noticeably darker base so the sweep is visible against
    // the off-white (F1F5F9) app background; highlight lifts to near-white.
    final baseColor =
        isLight ? AppColors.neutral300 : AppColors.darkSurfaceVariant;
    final highlightColor = isLight
        ? Colors.white.withValues(alpha: 0.90)
        : AppColors.brandPrimaryLight.withValues(alpha: 0.14);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              // Diagonal sweep: moves from off-screen-left to off-screen-right
              begin: Alignment(-1.5 + t * 3.0, -0.5),
              end: Alignment(-0.5 + t * 3.0, 0.5),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.35, 0.50, 0.65],
            ),
          ),
        );
      },
    );
  }
}
