import 'package:flutter/material.dart';

class ShimmerSkeleton extends StatefulWidget {
  const ShimmerSkeleton({
    super.key, 
    this.height = 120, 
    this.width,
    this.borderRadius = 16,
  });
  
  final double height;
  final double? width;
  final double borderRadius;

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                theme.colorScheme.surfaceContainerHighest,
                theme.colorScheme.onSurface.withOpacity(0.08), // More contrast
                theme.colorScheme.surfaceContainerHighest,
              ],
              stops: const [0.3, 0.5, 0.7], // Tighter beam
              begin: Alignment(-1.0 + (_controller.value * 3), -0.3),
              end: Alignment(1.0 + (_controller.value * 3), 0.3),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        );
      },
    );
  }
}
