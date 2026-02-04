import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';

/// Shimmer that mirrors the manage booking page layout: detail card + action buttons.
/// Uses full width and responsive layout to match real content across devices.
class ManageBookingShimmer extends StatelessWidget {
  const ManageBookingShimmer({super.key});

  static const _cardRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    return ShimmerWrapper(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailCardShimmer(sizes: sizes),
            Gap(sizes.paddingLarge),
            _ActionsShimmer(sizes: sizes),
            Gap(sizes.paddingXxl),
          ],
        ),
      ),
    );
  }
}

class _DetailCardShimmer extends StatelessWidget {
  const _DetailCardShimmer({required this.sizes});

  final AppSizes sizes;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: EdgeInsets.all(sizes.paddingMedium),
      decoration: BoxDecoration(
        color: colors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(ManageBookingShimmer._cardRadius),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailRowShimmer(sizes: sizes),
          Gap(sizes.paddingSmall),
          _DetailRowShimmer(sizes: sizes),
          Gap(sizes.paddingSmall),
          _DetailRowShimmer(sizes: sizes),
          Gap(sizes.paddingSmall),
          _DetailRowShimmer(sizes: sizes),
          Gap(sizes.paddingSmall),
          _DetailRowShimmer(sizes: sizes),
          Gap(sizes.paddingMedium),
          LayoutBuilder(
            builder:
                (_, c) => ShimmerPlaceholder(
                  width: c.maxWidth,
                  height: 1,
                  borderRadius: BorderRadius.circular(2),
                ),
          ),
          Gap(sizes.paddingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerPlaceholder(
                width: 60,
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
              ShimmerPlaceholder(
                width: 70,
                height: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRowShimmer extends StatelessWidget {
  const _DetailRowShimmer({required this.sizes});

  final AppSizes sizes;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerPlaceholder(
          width: 20,
          height: 20,
          borderRadius: BorderRadius.circular(4),
        ),
        Gap(sizes.paddingSmall),
        Expanded(
          child: LayoutBuilder(
            builder:
                (_, c) => ShimmerPlaceholder(
                  width: c.maxWidth,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
          ),
        ),
      ],
    );
  }
}

class _ActionsShimmer extends StatelessWidget {
  const _ActionsShimmer({required this.sizes});

  final AppSizes sizes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder:
              (_, c) => ShimmerPlaceholder(
                width: c.maxWidth,
                height: sizes.buttonHeightBig,
                borderRadius: BorderRadius.circular(sizes.borderRadius),
              ),
        ),
        Gap(sizes.paddingSmall),
        LayoutBuilder(
          builder:
              (_, c) => ShimmerPlaceholder(
                width: c.maxWidth,
                height: sizes.buttonHeightBig,
                borderRadius: BorderRadius.circular(sizes.borderRadius),
              ),
        ),
      ],
    );
  }
}
