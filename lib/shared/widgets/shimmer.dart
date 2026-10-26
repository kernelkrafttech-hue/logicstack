import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Animated gradient overlay used by skeleton placeholders. Avoids pulling
/// in an external package — the implementation is intentionally small.
class Shimmer extends StatefulWidget {
  const Shimmer({required this.child, super.key});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color base = isDark
        ? AppColors.navy.withValues(alpha: 0.6)
        : AppColors.lightGray;
    final Color highlight = isDark
        ? AppColors.navyMuted.withValues(alpha: 0.6)
        : AppColors.white;

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final double t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.0 - 2 * t, 0),
              end: Alignment(1.0 - 2 * t, 0),
              colors: <Color>[base, highlight, base],
              stops: const <double>[0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A solid-coloured rounded rectangle sized for skeleton layouts. Wrap one
/// or more of these in a [Shimmer] to get the standard "loading content"
/// effect.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    this.height = 16,
    this.width = double.infinity,
    this.radius = 8,
    super.key,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppColors.navy : AppColors.lightGray,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder shaped like a [RequestCard] / [PropertyCard] / etc. — a
/// rounded surface with two text lines and a leading square.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navy : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.navyMuted.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Shimmer(
        child: Row(
          children: const <Widget>[
            SkeletonBlock(height: 40, width: 40, radius: 10),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SkeletonBlock(height: 14, width: 180),
                  SizedBox(height: 8),
                  SkeletonBlock(height: 12, width: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders [count] [SkeletonRow]s with consistent spacing — drop in for any
/// list-style screen while the underlying stream is loading.
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.count = 4, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          if (i != 0) const SizedBox(height: 12),
          const SkeletonRow(),
        ],
      ],
    );
  }
}
