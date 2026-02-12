import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:barber/core/theme/app_colors.dart';

/// A box placeholder that shows a shimmer effect. Use inside [ShimmerWrapper].
class ShimmerPlaceholder extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure brand config colors are available
    final colors = ref.watch(appColorsProvider);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.menuBackgroundColor,
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
    );
  }
}

/// Which shimmer style to use. [home] for user-facing screens, [dashboard] for admin.
enum ShimmerVariant {
  home,
  dashboard,
}

/// Wraps [child] with [Shimmer.fromColors] using theme-based base and highlight.
/// Use for loading skeletons; place [ShimmerPlaceholder] widgets inside [child].
/// [variant] defaults to [ShimmerVariant.home]; use [ShimmerVariant.dashboard] in dashboard tabs.
class ShimmerWrapper extends ConsumerWidget {
  const ShimmerWrapper({
    super.key,
    required this.child,
    this.variant = ShimmerVariant.home,
  });

  final Widget child;
  final ShimmerVariant variant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ensure brand config colors are available
    final colors = ref.watch(appColorsProvider);
    final Color base;
    final Color highlight;
    switch (variant) {
      case ShimmerVariant.home:
        base = colors.menuBackgroundColor;
        highlight = colors.borderColor.withValues(alpha: 0.4);
        break;
      case ShimmerVariant.dashboard:
        base = colors.primaryColor.withValues(alpha: 0.06);
        highlight = colors.primaryColor.withValues(alpha: 0.18);
        break;
    }
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: child,
    );
  }
}
