import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dartz/dartz.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/stats/di.dart' as stats_di;
import 'package:barber/features/stats/domain/entities/dashboard_stats_entity.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/user_role.dart';
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
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;

  if (user == null || user.barberId.isEmpty) return null;

  final barberRepo = ref.watch(barbers_di.barberRepositoryProvider);
  final r = await barberRepo.getById(user.barberId);
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

/// Manages the current date range window for the calendar.
/// Starts with 10-day window (today - 2 to today + 7), expands when user navigates beyond range.
final calendarWindowProvider = StateProvider.autoDispose<DateTimeRange>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return DateTimeRange(
    start: today.subtract(const Duration(days: 2)),
    end: today.add(const Duration(days: 7)),
  );
});

/// Stream of appointments for the current calendar window.
/// Uses ref.keepAlive() to prevent disposal when switching tabs.
/// This is the ONLY provider that queries Firestore for calendar data.
final calendarWindowAppointmentsProvider =
    StreamProvider.autoDispose<List<AppointmentEntity>>((ref) {
      final window = ref.watch(calendarWindowProvider);
      final userAsync = ref.watch(currentUserProvider);
      final user = userAsync.valueOrNull;
      final apptRepo = ref.watch(booking_di.appointmentRepositoryProvider);

      // Keep stream alive to prevent re-reads on tab switches
      final link = ref.keepAlive();

      // Auto-dispose after 5 minutes of inactivity to free memory
      Timer? timer;
      ref.onDispose(() => timer?.cancel());
      ref.onCancel(() {
        timer = Timer(const Duration(minutes: 5), () {
          link.close();
        });
      });
      ref.onResume(() {
        timer?.cancel();
      });

      if (user == null) {
        if (userAsync.isLoading) {
          return Stream.fromFuture(Completer<List<AppointmentEntity>>().future);
        }
        return Stream.value([]);
      }

      if (user.barberId.isNotEmpty) {
        return apptRepo.watchAppointmentsForBarberInRange(
          user.barberId,
          window.start,
          window.end,
        );
      }

      return ref.watch(currentBarberProvider.future).asStream().asyncExpand((
        barber,
      ) {
        if (barber == null) {
          return Stream.value([]);
        }
        return apptRepo.watchAppointmentsForBarberInRange(
          barber.barberId,
          window.start,
          window.end,
        );
      });
    });

/// Appointments for a specific date, filtered from the window provider.
/// This does NOT query Firestore - it filters from already-loaded data.
/// Selecting different dates will NOT trigger new reads.
final appointmentsForDateProvider = Provider.autoDispose
    .family<AsyncValue<List<AppointmentEntity>>, DateTime>((ref, date) {
      final windowAsync = ref.watch(calendarWindowAppointmentsProvider);

      return windowAsync.whenData((appointments) {
        // Filter for the specific date (client-side, zero reads)
        final filtered =
            appointments.where((appointment) {
              final appointmentDate = appointment.startTime;
              return appointmentDate.year == date.year &&
                  appointmentDate.month == date.month &&
                  appointmentDate.day == date.day;
            }).toList();

        // Already sorted by start_time from Firestore query
        return filtered;
      });
    });

/// Calendar markers showing which days have appointments.
/// Uses data from the existing window - zero additional reads.
/// Returns a map of date -> appointment count for marker display.
final calendarMarkersProvider = Provider.autoDispose<Map<DateTime, int>>((ref) {
  final windowAsync = ref.watch(calendarWindowAppointmentsProvider);

  return windowAsync.when(
    data: (appointments) {
      final Map<DateTime, int> markers = {};

      for (final appointment in appointments) {
        final date = DateTime(
          appointment.startTime.year,
          appointment.startTime.month,
          appointment.startTime.day,
        );
        markers[date] = (markers[date] ?? 0) + 1;
      }

      return markers;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

/// Expands the calendar window to include the target date if needed.
/// Call this when user navigates to a date outside current window.
/// Merges with existing window to prevent data loss.
void expandCalendarWindowIfNeeded(WidgetRef ref, DateTime targetDate) {
  final currentWindow = ref.read(calendarWindowProvider);
  final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);

  // Check if target is outside current window
  if (targetDay.isBefore(currentWindow.start) ||
      targetDay.isAfter(currentWindow.end)) {
    // Expand window to include target date while keeping existing range
    // This merges the windows instead of replacing, preventing data loss
    final newStart =
        targetDay.isBefore(currentWindow.start)
            ? targetDay.subtract(const Duration(days: 5))
            : currentWindow.start;

    final newEnd =
        targetDay.isAfter(currentWindow.end)
            ? targetDay.add(const Duration(days: 10))
            : currentWindow.end;

    ref.read(calendarWindowProvider.notifier).state = DateTimeRange(
      start: newStart,
      end: newEnd,
    );
  }
}

final dashboardBrandIdProvider = Provider.autoDispose<String>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  final flavorBrandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;

  debugPrint(
    'DashboardBrandIdProvider: user=${user?.userId}, role=${user?.role}, brandId=${user?.brandId}, flavor=$flavorBrandId',
  );

  // For staff (superadmin/barber), force their assigned brand ID if available
  if (user != null &&
      (user.role == UserRole.superadmin || user.role == UserRole.barber) &&
      user.brandId.isNotEmpty) {
    debugPrint('DashboardBrandIdProvider: Using user brandId: ${user.brandId}');
    return user.brandId;
  }

  debugPrint(
    'DashboardBrandIdProvider: Using default/flavor: ${flavorBrandId.isNotEmpty ? flavorBrandId : 'default'}',
  );
  return flavorBrandId.isNotEmpty ? flavorBrandId : 'default';
});

final dashboardBrandNotifierProvider = StateNotifierProvider.autoDispose<
  DashboardBrandNotifier,
  BaseState<BrandEntity?>
>((ref) {
  final brandRepo = ref.watch(brandRepositoryProvider);
  final brandId = ref.watch(dashboardBrandIdProvider);
  return DashboardBrandNotifier(brandRepo, brandId);
});

final dashboardLocationsNotifierProvider = StateNotifierProvider.autoDispose<
  DashboardLocationsNotifier,
  BaseState<List<LocationEntity>>
>((ref) {
  final locationRepo = ref.watch(locationRepositoryProvider);
  final brandId = ref.watch(dashboardBrandIdProvider);
  return DashboardLocationsNotifier(locationRepo, brandId);
});

/// Locations state for the dashboard locations tab. Reuses home data when on default brand
/// so we avoid a duplicate Firestore read when the tab mounts (home already loaded locations).
final dashboardLocationsViewProvider = Provider<
  BaseState<List<LocationEntity>>
>((ref) {
  final dashboardState = ref.watch(dashboardLocationsNotifierProvider);
  final homeState = ref.watch(home_di.homeNotifierProvider);
  final brandId = ref.watch(dashboardBrandIdProvider);
  final flavorBrandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final effectiveFlavorBrandId =
      flavorBrandId.isNotEmpty ? flavorBrandId : 'default';

  if (dashboardState is BaseData<List<LocationEntity>> ||
      dashboardState is BaseError<List<LocationEntity>>) {
    return dashboardState;
  }
  // optimization: if dashboard brand == flavor brand, re-use home's loaded data
  if (brandId == effectiveFlavorBrandId &&
      homeState is BaseData<HomeData> &&
      homeState.data.brand?.brandId == brandId) {
    return BaseData(homeState.data.locations);
  }
  return dashboardState;
});

final dashboardServicesNotifierProvider = StateNotifierProvider.autoDispose<
  DashboardServicesNotifier,
  BaseState<List<ServiceEntity>>
>((ref) {
  final serviceRepo = ref.watch(services_di.serviceRepositoryProvider);
  final brandId = ref.watch(dashboardBrandIdProvider);
  return DashboardServicesNotifier(serviceRepo, brandId);
});

final dashboardRewardsNotifierProvider = StateNotifierProvider.autoDispose<
  DashboardRewardsNotifier,
  BaseState<List<RewardEntity>>
>((ref) {
  final rewardRepo = ref.watch(rewards_di.rewardRepositoryProvider);
  final brandId = ref.watch(dashboardBrandIdProvider);
  return DashboardRewardsNotifier(rewardRepo, brandId);
});

final dashboardBarbersNotifierProvider = StateNotifierProvider.autoDispose<
  DashboardBarbersNotifier,
  BaseState<List<BarberEntity>>
>((ref) {
  final barberRepo = ref.watch(barbers_di.barberRepositoryProvider);
  final brandId = ref.watch(dashboardBrandIdProvider);
  return DashboardBarbersNotifier(barberRepo, brandId);
});

/// Provider for current barber's effective working hours.
/// Returns workingHoursOverride if set, otherwise location's default hours.
/// Used by barber shift tab to display working schedule.
final barberEffectiveWorkingHoursProvider = FutureProvider.autoDispose((
  ref,
) async {
  final barberAsync = await ref.watch(currentBarberProvider.future);
  final barber = barberAsync;

  if (barber == null) return null;

  // If barber has override, use it
  if (barber.workingHoursOverride != null &&
      barber.workingHoursOverride!.isNotEmpty) {
    return barber.workingHoursOverride;
  }

  // Otherwise get location's default hours
  final locationRepo = ref.watch(locationRepositoryProvider);
  final result = await locationRepo.getById(barber.locationId);
  return result.fold(
    (_) => null,
    (location) => location?.workingHours,
  );
});
