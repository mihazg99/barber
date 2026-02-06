import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/firebase/default_brand_id.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/barbers/di.dart' as barbers_di;
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/home/presentation/bloc/home_notifier.dart';
import 'package:barber/features/home/presentation/bloc/loyalty_card_notifier.dart';
import 'package:barber/features/booking/di.dart' as booking_di;
import 'package:barber/features/locations/di.dart';
import 'package:barber/features/services/di.dart' as services_di;
import 'package:barber/features/services/domain/entities/service_entity.dart';

final homeNotifierProvider =
    StateNotifierProvider<HomeNotifier, BaseState<HomeData>>((ref) {
      final configBrandId =
          ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
      final brandId =
          configBrandId.isNotEmpty ? configBrandId : fallbackBrandId;
      return HomeNotifier(
        ref.watch(brandRepositoryProvider),
        ref.watch(locationRepositoryProvider),
        brandId,
      );
    });

/// Flip state for the loyalty card (front/back). AutoDispose.
final loyaltyCardNotifierProvider =
    StateNotifierProvider.autoDispose<LoyaltyCardNotifier, LoyaltyCardState>(
        (ref) => LoyaltyCardNotifier());

/// Barbers for the default brand. Loaded for quick-action booking.
final barbersForHomeProvider = FutureProvider<List<BarberEntity>>((ref) async {
  final configBrandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final brandId =
      configBrandId.isNotEmpty ? configBrandId : fallbackBrandId;
  final repo = ref.watch(barbers_di.barberRepositoryProvider);
  final result = await repo.getByBrandId(brandId);
  return result.fold(
    (_) => <BarberEntity>[],
    (list) => list.where((b) => b.active).toList(),
  );
});

/// Services for the default brand. Loaded to speed up booking.
final servicesForHomeProvider = FutureProvider<List<ServiceEntity>>((ref) async {
  final configBrandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final brandId =
      configBrandId.isNotEmpty ? configBrandId : fallbackBrandId;
  final repo = ref.watch(services_di.serviceRepositoryProvider);
  final result = await repo.getByBrandId(brandId);
  return result.fold(
    (_) => <ServiceEntity>[],
    (list) => list,
  );
});

/// Next upcoming scheduled appointment for the current user, or null.
/// Stream so when barber marks visit complete (lock cleared, status updated) the UI updates immediately.
/// When [isLoggingOutProvider] is true, returns null stream so listeners are cancelled before signOut (avoids PERMISSION_DENIED).
final upcomingAppointmentProvider = StreamProvider<AppointmentEntity?>((ref) {
  if (ref.watch(isLoggingOutProvider)) return Stream.value(null);
  final uidAsync = ref.watch(currentUserIdProvider);
  final uid = uidAsync.valueOrNull;
  if (uid == null || uid.isEmpty) return Stream.value(null);
  final repo = ref.watch(booking_di.appointmentRepositoryProvider);
  return repo.watchActiveAppointmentId(uid).asyncExpand((activeId) {
    if (activeId == null || activeId.isEmpty) return Stream.value(null);
    return repo.watchAppointment(activeId).map((appointment) {
      if (appointment == null) return null;
      if (appointment.status != AppointmentStatus.scheduled) return null;
      if (!appointment.startTime.isAfter(DateTime.now())) return null;
      return appointment;
    });
  });
});
