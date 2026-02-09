import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/features/dashboard/di.dart' as dashboard_di;
import 'package:barber/features/time_off/data/repositories/time_off_repository_impl.dart';
import 'package:barber/features/time_off/domain/entities/time_off_entity.dart';
import 'package:barber/features/time_off/domain/repositories/time_off_repository.dart';

/// Repository provider for time-off operations.
final timeOffRepositoryProvider = Provider<TimeOffRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return TimeOffRepositoryImpl(firestore);
});

/// Stream of time-off periods for the current barber.
/// Returns empty list if user is not a barber.
final barberTimeOffProvider = StreamProvider.autoDispose<List<TimeOffEntity>>(
  (ref) {
    final currentBarberAsync = ref.watch(dashboard_di.currentBarberProvider);
    final currentBarber = currentBarberAsync.valueOrNull;

    if (currentBarber == null) {
      return Stream.value([]);
    }

    final timeOffRepo = ref.watch(timeOffRepositoryProvider);
    return timeOffRepo.watchByBarberId(currentBarber.barberId);
  },
);

/// Future provider to check if a barber has time-off on a specific date.
/// Returns true if barber has time-off covering the date.
final barberHasTimeOffOnDateProvider = FutureProvider.autoDispose
    .family<bool, ({String barberId, DateTime date})>((ref, params) async {
      final timeOffRepo = ref.watch(timeOffRepositoryProvider);
      final result = await timeOffRepo.getByBarberIdAndDate(
        params.barberId,
        params.date,
      );

      return result.fold(
        (_) => false, // On error, assume no time-off
        (timeOffList) => timeOffList.isNotEmpty,
      );
    });
