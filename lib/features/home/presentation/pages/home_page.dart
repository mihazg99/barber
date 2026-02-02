import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/navigation/presentation/widgets/bottom_nav_bar.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/home/presentation/widgets/barbers_section.dart';
import 'package:barber/features/home/presentation/widgets/home_header.dart';
import 'package:barber/features/home/presentation/widgets/home_section_title.dart';
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
            BaseInitial() => const _HomeLoading(),
            BaseLoading() => const _HomeLoading(),
            BaseData() => const _HomeContent(),
            BaseError() => const _HomeError(),
          },
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class _HomeLoading extends StatelessWidget {
  const _HomeLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          context.appColors.primaryColor,
        ),
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final upcomingAppointment = ref.watch(upcomingAppointmentProvider).valueOrNull;
    final barbersAsync = ref.watch(barbersForHomeProvider);
    final servicesAsync = ref.watch(servicesForHomeProvider);

    final data = homeState is BaseData<HomeData> ? homeState.data : const HomeData();
    final locations = data.locations;

    String? locationName;
    if (upcomingAppointment != null) {
      try {
        locationName = locations
            .firstWhere(
              (loc) => loc.locationId == upcomingAppointment.locationId,
            )
            .name;
      } catch (_) {
        locationName = null;
      }
    }

    const horizontalPadding = 20.0;
    const sectionSpacing = 28.0;

    final barbers = barbersAsync.valueOrNull ?? [];
    final services = servicesAsync.valueOrNull ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (currentUser != null) ...[
                  LoyaltyCard(user: currentUser),
                  Gap(sectionSpacing),
                ],
                const HomeSectionTitle(title: 'Upcoming'),
                Gap(context.appSizes.paddingSmall),
                if (upcomingAppointment != null)
                  UpcomingBookingCard(
                    appointment: upcomingAppointment,
                    locationName: locationName,
                  )
                else
                  NoUpcomingBookingCTA(
                    onTap: () => context.push(AppRoute.booking.path),
                  ),
                Gap(sectionSpacing),
                if (barbers.isNotEmpty) ...[
                  BarbersSection(barbers: barbers, title: 'Book with a barber'),
                  Gap(sectionSpacing),
                ],
                if (services.isNotEmpty) ...[
                  ServicesSection(services: services, title: 'Popular services'),
                  Gap(sectionSpacing),
                ],
                NearbyLocationsSection(
                  locations: locations,
                  title: 'Nearby barbershop',
                ),
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
