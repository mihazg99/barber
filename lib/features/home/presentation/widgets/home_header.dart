import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/home/di.dart';

/// Slim home header: brand left, notifications right. No greeting/date to make space for premium loyalty card.
/// Shows shimmer when loading; content when data is ready (same pattern as [LocationsList]).
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);

    return switch (homeState) {
      BaseInitial() => const _HeaderShimmer(),
      BaseLoading() => const _HeaderShimmer(),
      BaseData(:final data) => _HeaderContent(
        brandName: data.brandName,
        brandLogoUrl: data.brand?.logoUrl,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _HeaderContent extends ConsumerWidget {
  const _HeaderContent({
    required this.brandName,
    this.brandLogoUrl,
  });

  final String brandName;
  final String? brandLogoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(flavorConfigProvider);
    final brandConfig = flavor.values.brandConfig;
    final logoPath =
        brandConfig.logoPath.isNotEmpty ? brandConfig.logoPath : null;
    final logoUrl = brandLogoUrl?.isNotEmpty == true ? brandLogoUrl : null;
    final hasLogo =
        (logoPath != null && logoPath.isNotEmpty) ||
        (logoUrl != null && logoUrl.isNotEmpty);

    const _logoHeight = 40.0;
    final _logoWidth = logoUrl != null ? 120.0 : 40.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.appSizes.paddingMedium,
        context.appSizes.paddingMedium,
        context.appSizes.paddingMedium,
        context.appSizes.paddingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasLogo) ...[
                      _BrandLogo(
                        logoUrl: logoUrl,
                        logoPath: logoPath,
                        width: _logoWidth,
                        height: _logoHeight,
                      ),
                      const Gap(14),
                    ],
                    Flexible(
                      child: Text(
                        brandName,
                        style: context.appTextStyles.h2.copyWith(
                          fontSize: hasLogo ? 17 : 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: context.appColors.primaryTextColor,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_outlined,
                  color: context.appColors.primaryTextColor,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Brand logo: network or asset, with consistent sizing and error handling.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({
    this.logoUrl,
    this.logoPath,
    required this.width,
    required this.height,
  });

  final String? logoUrl;
  final String? logoPath;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: logoUrl != null
            ? Image.network(
                logoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _buildPlaceholder(context),
              )
            : Image.asset(
                logoPath!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(context),
              ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.appColors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.store_rounded,
        color: context.appColors.primaryColor,
        size: 22,
      ),
    );
  }
}

class _HeaderShimmer extends StatelessWidget {
  const _HeaderShimmer();

  @override
  Widget build(BuildContext context) {
    final padding = context.appSizes.paddingMedium;
    return ShimmerWrapper(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          padding,
          padding,
          padding,
          context.appSizes.paddingSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ShimmerPlaceholder(
                  width: 120,
                  height: 40,
                  borderRadius: BorderRadius.circular(8),
                ),
                const Gap(14),
                Expanded(
                  child: ShimmerPlaceholder(
                    width: double.infinity,
                    height: 18,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                ShimmerPlaceholder(
                  width: 44,
                  height: 44,
                  borderRadius: BorderRadius.circular(22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
