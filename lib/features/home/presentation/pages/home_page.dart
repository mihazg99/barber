import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/navigation/presentation/widgets/bottom_nav_bar.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/presentation/widgets/barbers_section.dart';
import 'package:barber/features/home/presentation/widgets/home_header.dart';
import 'package:barber/features/home/presentation/widgets/loyalty_card.dart';
import 'package:barber/features/home/presentation/widgets/nearby_locations_section.dart';
import 'package:barber/features/home/presentation/widgets/services_section.dart';
import 'package:barber/features/home/presentation/widgets/upcoming_booking_card.dart';

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

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: switch (homeState) {
            BaseError() => const _HomeError(),
            _ => const _HomeBody(),
          },
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  static const _horizontalPadding = 20.0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LoyaltyCard(),
                const UpcomingBooking(),
                const BarbersSection(),
                const ServicesSection(),
                const NearbyLocationsSection(),
                Gap(context.appSizes.paddingXxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeError extends ConsumerWidget {
  const _HomeError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);
    final message = switch (homeState) {
      BaseError(:final message) => message,
      _ => '',
    };

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
