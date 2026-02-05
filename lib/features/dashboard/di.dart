import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/booking/di.dart' as booking_di;
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/dashboard/presentation/bloc/barber_home_notifier.dart';
import 'package:barber/features/dashboard/presentation/bloc/dashboard_brand_notifier.dart';
import 'package:barber/features/dashboard/presentation/bloc/dashboard_barbers_notifier.dart';
import 'package:barber/features/dashboard/presentation/bloc/dashboard_locations_notifier.dart';
import 'package:barber/features/dashboard/presentation/bloc/dashboard_rewards_notifier.dart';
import 'package:barber/features/dashboard/presentation/bloc/dashboard_services_notifier.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/barbers/di.dart' as barbers_di;
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/locations/di.dart';
import 'package:barber/features/rewards/domain/entities/reward_entity.dart';
import 'package:barber/features/rewards/di.dart' as rewards_di;
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:barber/features/services/di.dart' as services_di;

/// Selected tab index for barber dashboard (Home=0, Bookings=1, Shift=2).
/// Barber home can set this to switch to Bookings from "View bookings" CTA.
final dashboardBarberTabIndexProvider = StateProvider<int>((ref) => 0);

/// Barber home tab state. AutoDispose so state is cleared when leaving dashboard.
final barberHomeNotifierProvider = StateNotifierProvider.autoDispose<
  BarberHomeNotifier,
  BaseState<BarberHomeData>
>((ref) => BarberHomeNotifier());

/// Stream of upcoming (today or future) scheduled appointments for the current barber.
/// When barber marks visit complete, UI updates automatically.
/// Returns [] if user is not a linked barber (e.g. superadmin without barber record).
final barberUpcomingAppointmentsProvider =
    StreamProvider.autoDispose<List<AppointmentEntity>>((ref) {
  final uid = ref.watch(currentUserProvider).valueOrNull?.userId;
  if (uid == null || uid.isEmpty) return Stream.value([]);
  final barberRepo = ref.watch(barbers_di.barberRepositoryProvider);
  final apptRepo = ref.watch(booking_di.appointmentRepositoryProvider);
  return Stream.fromFuture(
    barberRepo.getByUserId(uid).then((r) => r.getOrElse(() => null)),
  ).asyncExpand((barber) {
    if (barber == null) return Stream.value([]);
    return apptRepo.watchUpcomingAppointmentsForBarber(barber.barberId);
  });
});

final dashboardBrandNotifierProvider =
    StateNotifierProvider<DashboardBrandNotifier, BaseState<BrandEntity?>>((
      ref,
    ) {
      final brandRepo = ref.watch(brandRepositoryProvider);
      final brandId =
          ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
      final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';
      return DashboardBrandNotifier(brandRepo, effectiveBrandId);
    });

final dashboardLocationsNotifierProvider = StateNotifierProvider<
  DashboardLocationsNotifier,
  BaseState<List<LocationEntity>>
>((ref) {
  final locationRepo = ref.watch(locationRepositoryProvider);
  final brandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';
  return DashboardLocationsNotifier(locationRepo, effectiveBrandId);
});

final dashboardServicesNotifierProvider = StateNotifierProvider<
  DashboardServicesNotifier,
  BaseState<List<ServiceEntity>>
>((ref) {
  final serviceRepo = ref.watch(services_di.serviceRepositoryProvider);
  final brandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';
  return DashboardServicesNotifier(serviceRepo, effectiveBrandId);
});

final dashboardRewardsNotifierProvider = StateNotifierProvider.autoDispose<
  DashboardRewardsNotifier,
  BaseState<List<RewardEntity>>
>((ref) {
  final rewardRepo = ref.watch(rewards_di.rewardRepositoryProvider);
  final brandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';
  return DashboardRewardsNotifier(rewardRepo, effectiveBrandId);
});

final dashboardBarbersNotifierProvider = StateNotifierProvider<
  DashboardBarbersNotifier,
  BaseState<List<BarberEntity>>
>((ref) {
  final barberRepo = ref.watch(barbers_di.barberRepositoryProvider);
  final brandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';
  return DashboardBarbersNotifier(barberRepo, effectiveBrandId);
});
