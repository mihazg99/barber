import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
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
        brandLogoUrl: data.brand?.logoUrl,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({this.brandLogoUrl});

  /// Logo URL from brand entity (Firestore). Home header uses this exclusively.
  final String? brandLogoUrl;

  @override
  Widget build(BuildContext context) {
    const _logoHeight = 40.0;
    const _logoWidth = 120.0;
    final logoUrl =
        brandLogoUrl != null && brandLogoUrl!.trim().isNotEmpty
            ? brandLogoUrl!.trim()
            : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.appSizes.paddingMedium,
        context.appSizes.paddingMedium,
        context.appSizes.paddingMedium,
        context.appSizes.paddingSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _BrandLogo(
            logoUrl: logoUrl,
            width: _logoWidth,
            height: _logoHeight,
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            icon: Icon(
              Icons.settings_outlined,
              color: context.appColors.primaryTextColor,
              size: 24,
            ),
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
            ),
          ),
        ],
      ),
    );
  }
}

/// Brand logo from URL (Firestore brand entity). Shows placeholder while loading or on error.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({
    this.logoUrl,
    required this.width,
    required this.height,
  });

  final String? logoUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child:
            logoUrl != null && logoUrl!.isNotEmpty
                ? Image.network(
                  logoUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildPlaceholder(context);
                  },
                  errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                )
                : _buildPlaceholder(context),
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
                const Spacer(),
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
