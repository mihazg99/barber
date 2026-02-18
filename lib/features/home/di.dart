import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/user_role.dart';
import 'package:barber/features/barbers/di.dart' as barbers_di;
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/home/presentation/bloc/home_notifier.dart';
import 'package:barber/features/home/presentation/bloc/loyalty_card_notifier.dart';
import 'package:barber/features/home/presentation/bloc/upcoming_appointment_notifier.dart';
import 'package:barber/features/booking/di.dart' as booking_di;
import 'package:barber/features/locations/di.dart';
import 'package:barber/features/services/di.dart' as services_di;
import 'package:barber/features/services/domain/entities/service_entity.dart';

/// Determines the brand ID to use for the Home page.
/// - If staff (expert/admin) has an assigned brand, FORCE that brand.
/// - Otherwise, use the selected/locked brand.
final homeBrandIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;

  if (user != null &&
      (user.role == UserRole.superadmin || user.role == UserRole.barber) &&
      user.brandId.isNotEmpty) {
    debugPrint('[HomeBrandIdProvider] Using user brandId: ${user.brandId}');
    return user.brandId;
  }

  final locked = ref.watch(lockedBrandIdProvider);
  debugPrint('[HomeBrandIdProvider] Using locked brandId: $locked');
  return locked;
});

final homeNotifierProvider = StateNotifierProvider<
  HomeNotifier,
  BaseState<HomeData>
>((ref) {
  // Watch ONLY the brand ID.
  // If user profile updates but brand ID stays the same, this provider will NOT rebuild.
  final brandId = ref.watch(homeBrandIdProvider);

  // Return empty state if no brand selected (user will be redirected by router)
  if (brandId == null || brandId.isEmpty) {
    return HomeNotifier(
      ref.watch(brandRepositoryProvider),
      ref.watch(locationRepositoryProvider),
      '', // Empty brandId - won't load data
    );
  }

  return HomeNotifier(
    ref.watch(brandRepositoryProvider),
    ref.watch(locationRepositoryProvider),
    brandId,
  );
});

/// Flip state for the loyalty card (front/back). AutoDispose.
final loyaltyCardNotifierProvider =
    StateNotifierProvider.autoDispose<LoyaltyCardNotifier, LoyaltyCardState>(
      (ref) => LoyaltyCardNotifier(),
    );

/// Barbers for the selected brand. Loaded for quick-action booking.
final barbersForHomeProvider = FutureProvider<List<BarberEntity>>((ref) async {
  final brandId = ref.watch(lockedBrandIdProvider);
  // Return empty list if no brand selected
  if (brandId == null) {
    debugPrint('[BarbersForHome] No brand selected');
    return <BarberEntity>[];
  }

  debugPrint('[BarbersForHome] Loading barbers for brand: $brandId');
  final repo = ref.watch(barbers_di.barberRepositoryProvider);
  final brandRepo = ref.watch(brandRepositoryProvider);
  final brandResult = await brandRepo.getById(brandId);
  final version = brandResult.fold(
    (_) => null,
    (b) => b?.dataVersions['barbers'],
  );

  final result = await repo.getByBrandId(brandId, version: version);
  return result.fold(
    (failure) {
      debugPrint('[BarbersForHome] Error: ${failure.message}');
      return <BarberEntity>[];
    },
    (list) {
      final activeBarbers = list.where((b) => b.active).toList();
      debugPrint(
        '[BarbersForHome] Loaded ${activeBarbers.length} active barbers (${list.length} total)',
      );
      return activeBarbers;
    },
  );
});

/// Services for the selected brand. Loaded to speed up booking.
final servicesForHomeProvider = FutureProvider<List<ServiceEntity>>(
  (ref) async {
    final brandId = ref.watch(lockedBrandIdProvider);
    // Return empty list if no brand selected
    if (brandId == null) return <ServiceEntity>[];

    final repo = ref.watch(services_di.serviceRepositoryProvider);
    final brandRepo = ref.watch(brandRepositoryProvider);
    final brandResult = await brandRepo.getById(brandId);
    final version = brandResult.fold(
      (_) => null,
      (b) => b?.dataVersions['services'],
    );

    final result = await repo.getByBrandId(brandId, version: version);
    return result.fold(
      (_) => <ServiceEntity>[],
      (list) => list,
    );
  },
);

/// Next upcoming scheduled appointment for the current user within the selected brand, or null.
/// Stream so when barber marks visit complete (lock cleared, status updated) the UI updates immediately.
/// When [isLoggingOutProvider] is true, returns null stream so listeners are cancelled before signOut (avoids PERMISSION_DENIED).
final upcomingAppointmentProvider = StateNotifierProvider.autoDispose<
  UpcomingAppointmentNotifier,
  BaseState<AppointmentEntity?>
>(
  (ref) {
    if (ref.watch(isLoggingOutProvider)) {
      return UpcomingAppointmentNotifier(
        ref.watch(booking_di.appointmentRepositoryProvider),
        '',
        '',
      );
    }
    // Only rebuild if the User ID actually changes (not just profile updates)
    final uid = ref.watch(
      currentUserProvider.select((value) => value.valueOrNull?.userId),
    );
    final brandId = ref.watch(lockedBrandIdProvider);

    // Return empty notifier if no brand selected
    if (brandId == null) {
      return UpcomingAppointmentNotifier(
        ref.watch(booking_di.appointmentRepositoryProvider),
        uid ?? '',
        '', // Empty brandId - won't load data
      );
    }

    return UpcomingAppointmentNotifier(
      ref.watch(booking_di.appointmentRepositoryProvider),
      uid ?? '',
      brandId,
    );
  },
);
