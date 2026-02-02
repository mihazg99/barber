import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/navigation/presentation/widgets/bottom_nav_bar.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/presentation/widgets/home_header.dart';
import 'package:barber/features/home/presentation/widgets/locations_section.dart';
import 'package:barber/features/home/presentation/widgets/quick_action_card.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(homeNotifierProvider.notifier).load();
      });
      return null;
    }, []);

    final homeState = ref.watch(homeNotifierProvider);
    final flavor = ref.watch(flavorConfigProvider);
    final brandConfig = flavor.values.brandConfig;

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: switch (homeState) {
            BaseInitial() => _buildLoading(context),
            BaseLoading() => _buildLoading(context),
            BaseData(:final data) => _buildContent(
              context,
              brandName: data.brandName,
              logoPath:
                  brandConfig.logoPath.isNotEmpty ? brandConfig.logoPath : null,
              locations: data.locations,
            ),
            BaseError(:final message) => _buildError(context, ref, message),
          },
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          context.appColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required String brandName,
    String? logoPath,
    required List<LocationEntity> locations,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeader(brandName: brandName, logoPath: logoPath),
          Gap(context.appSizes.paddingMedium),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.appSizes.paddingMedium,
            ),
            child: Column(
              children: [
                QuickActionCard(
                  title: 'Book appointment',
                  icon: Icons.calendar_today,
                  onTap: () {
                    // TODO: Navigate to booking
                  },
                ),
                Gap(context.appSizes.paddingSmall),
                QuickActionCard(
                  title: 'Scan QR code',
                  icon: Icons.qr_code_scanner,
                  onTap: () => context.go(AppRoute.inventory.path),
                ),
                Gap(context.appSizes.paddingSmall),
                QuickActionCard(
                  title: 'Inventory',
                  icon: Icons.inventory_2,
                  onTap: () => context.go(AppRoute.inventory.path),
                ),
              ],
            ),
          ),
          Gap(context.appSizes.paddingLarge),
          LocationsSection(locations: locations),
          Gap(context.appSizes.paddingXxl),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    return Padding(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: context.appColors.errorColor,
          ),
          Gap(context.appSizes.paddingMedium),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appColors.secondaryTextColor,
              fontSize: 14,
            ),
          ),
          Gap(context.appSizes.paddingMedium),
          TextButton.icon(
            onPressed: () => ref.read(homeNotifierProvider.notifier).refresh(),
            icon: Icon(Icons.refresh, color: context.appColors.primaryColor),
            label: Text(
              'Retry',
              style: TextStyle(color: context.appColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
