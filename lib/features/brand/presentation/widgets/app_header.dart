import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/brand/di.dart' as brand_di;
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';

/// Unified app header: brand name (left) and settings gear (right). Opens end drawer on gear tap.
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavorTitle =
        ref.watch(flavorConfigProvider).values.brandConfig.appTitle;

    // Watch default brand provider to detect loading state
    final defaultBrandAsync = ref.watch(brand_di.defaultBrandProvider);

    // Try to get dynamic brand name from dashboard state (superadmin)
    final dashboardState = ref.watch(dashboardBrandNotifierProvider);
    final dashboardBrand =
        dashboardState is BaseData<BrandEntity?> ? dashboardState.data : null;

    // Try to get dynamic brand name from home state (user/barber)
    final homeState = ref.watch(homeNotifierProvider);
    final homeBrand =
        homeState is BaseData<HomeData> ? homeState.data.brand : null;

    final brand = dashboardBrand ?? homeBrand ?? defaultBrandAsync.valueOrNull;
    final brandTitle = brand?.name;
    final logoUrl = brand?.logoUrl;

    // Show shimmer if brand is loading and we have a locked brand ID
    final lockedBrandId = ref.watch(brand_di.lockedBrandIdProvider);
    final isBrandLoading =
        defaultBrandAsync.isLoading &&
        lockedBrandId != null &&
        brandTitle == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Brand logo (Hero widget for portal transition)
          if (logoUrl != null && logoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Hero(
                tag: 'brand-portal',
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: context.appColors.secondaryColor,
                        );
                      },
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: context.appColors.secondaryColor,
                            child: Icon(
                              Icons.store,
                              size: 20,
                              color: context.appColors.primaryTextColor,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  isBrandLoading
                      ? ShimmerWrapper(
                        child: ShimmerPlaceholder(
                          width: 120,
                          height: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                      : Text(
                        brandTitle ?? flavorTitle,
                        style: context.appTextStyles.h1.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          height: 1.2,
                          color: context.appColors.primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
            ),
          ),
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
