import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:barber/core/theme/app_colors.dart';

/// A box placeholder that shows a shimmer effect. Use inside [ShimmerWrapper].
class ShimmerPlaceholder extends StatelessWidget {
  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.menuBackgroundColor,
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
    );
  }
}

/// Wraps [child] with [Shimmer.fromColors] using theme-based base and highlight.
/// Use for loading skeletons; place [ShimmerPlaceholder] widgets inside [child].
class ShimmerWrapper extends StatelessWidget {
  const ShimmerWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final base = colors.menuBackgroundColor;
    final highlight = colors.borderColor.withValues(alpha: 0.4);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: child,
    );
  }
}
