import 'package:flutter/material.dart';

class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration shimmerDuration;

  const Shimmer({
    super.key,
    required this.child,
    this.shimmerDuration = const Duration(seconds: 2),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.shimmerDuration,
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.7),
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                    stops: [
                      _animation.value - 0.2,
                      _animation.value - 0.05,
                      _animation.value,
                      _animation.value + 0.05,
                      _animation.value + 0.2,
                    ],
                  ).createShader(rect);
                },
                blendMode: BlendMode.srcATop,
                child: SizedBox.expand(child: widget.child),
              );
            },
          ),
        ],
      ),
    );
  }
}
