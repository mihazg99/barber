import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';
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

    // Try to get dynamic brand name from dashboard state (superadmin)
    final dashboardState = ref.watch(dashboardBrandNotifierProvider);
    final dashboardBrandName =
        dashboardState is BaseData<BrandEntity?>
            ? dashboardState.data?.name
            : null;

    // Try to get dynamic brand name from home state (user/barber)
    final homeState = ref.watch(homeNotifierProvider);
    final homeBrandName =
        homeState is BaseData<HomeData> ? homeState.data.brand?.name : null;

    final brandTitle = dashboardBrandName ?? homeBrandName ?? flavorTitle;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                brandTitle,
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
