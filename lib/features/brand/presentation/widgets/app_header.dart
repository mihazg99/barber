import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/brand/di.dart';

/// Unified app header: brand logo (left) and gear icon (right). Opens end drawer on gear tap.
/// Uses [headerBrandLogoUrlProvider] so user, barber, and superadmin all share the same brand state.
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoAsync = ref.watch(headerBrandLogoUrlProvider);

    return logoAsync.when(
      data: (logoUrl) => _AppHeaderContent(logoUrl: logoUrl),
      loading: () => const _AppHeaderShimmer(),
      error: (_, __) => _AppHeaderContent(logoUrl: null),
    );
  }
}

class _AppHeaderContent extends StatelessWidget {
  const _AppHeaderContent({this.logoUrl});

  final String? logoUrl;

  static const _logoHeight = 40.0;
  static const _logoWidth = 120.0;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl != null && logoUrl!.trim().isNotEmpty
        ? logoUrl!.trim()
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
            logoUrl: url,
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

class _AppHeaderShimmer extends StatelessWidget {
  const _AppHeaderShimmer();

  @override
  Widget build(BuildContext context) {
    final padding = context.appSizes.paddingMedium;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding,
        padding,
        padding,
        context.appSizes.paddingSmall,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShimmerWrapper(
            child: ShimmerPlaceholder(
              width: 120,
              height: 40,
              borderRadius: BorderRadius.circular(8),
            ),
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
