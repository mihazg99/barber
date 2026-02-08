import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dartz/dartz.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/stats/di.dart' as stats_di;
import 'package:barber/features/stats/domain/entities/dashboard_stats_entity.dart';
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
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/home/di.dart' as home_di;
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

/// Current barber for the logged-in user (when they have a linked barber record).
final currentBarberProvider = FutureProvider.autoDispose<BarberEntity?>((
  ref,
) async {
  final uid = ref.watch(currentUserProvider).valueOrNull?.userId;
  if (uid == null || uid.isEmpty) return null;
  final barberRepo = ref.watch(barbers_di.barberRepositoryProvider);
  final r = await barberRepo.getByUserId(uid);
  return r.fold(
    (l) => null,
    (barber) => barber,
  );
});

/// Dashboard stats (daily + monthly) for a location. Uses pre-aggregated docs, no appointments query.
final dashboardStatsProvider = FutureProvider.autoDispose.family<
  Either<Failure, DashboardStatsEntity>,
  String
>((ref, locationId) async {
  if (locationId.isEmpty) return Left(FirestoreFailure('locationId required'));
  final statsRepo = ref.watch(stats_di.statsRepositoryProvider);
  return statsRepo.getDashboardStats(locationId, DateTime.now());
});

/// Stream of upcoming (today or future) scheduled appointments for the current barber.
/// When barber marks visit complete, UI updates automatically.
/// Returns [] if user is not a linked barber (e.g. superadmin without barber record).
final barberUpcomingAppointmentsProvider = StreamProvider.autoDispose<
  List<AppointmentEntity>
>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  final apptRepo = ref.watch(booking_di.appointmentRepositoryProvider);

  if (user == null) {
    if (userAsync.isLoading) {
      // Keep loading if we don't have a user yet
      return Stream.fromFuture(Completer<List<AppointmentEntity>>().future);
    }
    return Stream.value([]);
  }

  // If user doc has barberId, use it directly to save a read to the barbers collection.
  if (user.barberId.isNotEmpty) {
    return apptRepo.watchUpcomingAppointmentsForBarber(user.barberId);
  }

  // Fallback: use the currentBarberProvider which queries the barbers collection.
  return ref.watch(currentBarberProvider.future).asStream().asyncExpand((
    barber,
  ) {
    if (barber == null) {
      return Stream.value([]);
    }
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

/// Locations state for the dashboard locations tab. Reuses home data when on default brand
/// so we avoid a duplicate Firestore read when the tab mounts (home already loaded locations).
final dashboardLocationsViewProvider =
    Provider<BaseState<List<LocationEntity>>>((ref) {
      final dashboardState = ref.watch(dashboardLocationsNotifierProvider);
      final homeState = ref.watch(home_di.homeNotifierProvider);
      final brandId =
          ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
      final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';

      if (dashboardState is BaseData<List<LocationEntity>> ||
          dashboardState is BaseError<List<LocationEntity>>) {
        return dashboardState;
      }
      if (homeState is BaseData<HomeData> &&
          homeState.data.brand?.brandId == effectiveBrandId) {
        return BaseData(homeState.data.locations);
      }
      return dashboardState;
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
