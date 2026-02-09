import 'package:barber/core/di.dart';
import 'package:barber/features/booking/data/repositories/availability_repository_impl.dart';
import 'package:barber/features/booking/data/repositories/appointment_repository_impl.dart';
import 'package:barber/features/booking/data/services/booking_transaction.dart';
import 'package:barber/features/booking/domain/repositories/availability_repository.dart';
import 'package:barber/features/booking/domain/repositories/appointment_repository.dart';
import 'package:barber/features/booking/domain/entities/booking_state.dart';
import 'package:barber/features/booking/domain/entities/time_slot.dart';
import 'package:barber/features/booking/domain/use_cases/calculate_free_slots.dart';
import 'package:barber/features/booking/presentation/bloc/booking_notifier.dart';
import 'package:barber/features/booking/presentation/bloc/edit_booking_notifier.dart';
import 'package:barber/features/booking/presentation/bloc/manage_booking_notifier.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/barbers/di.dart' as barbers_di;
import 'package:barber/features/locations/di.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/services/di.dart' as services_di;
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/time_off/di.dart' as time_off_di;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return AvailabilityRepositoryImpl(firestore);
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return AppointmentRepositoryImpl(firestore);
});

final bookingTransactionProvider = Provider<BookingTransaction>((ref) {
  return BookingTransaction(ref.watch(firebaseFirestoreProvider));
});

final calculateFreeSlotsProvider = Provider<CalculateFreeSlots>((ref) {
  return CalculateFreeSlots(
    ref.watch(availabilityRepositoryProvider),
    ref.watch(time_off_di.timeOffRepositoryProvider),
  );
});

final manageBookingNotifierProvider = StateNotifierProvider.family<
  ManageBookingNotifier,
  BaseState<ManageBookingData>,
  String
>((ref, appointmentId) {
  final isStaff = ref.watch(isStaffProvider);
  return ManageBookingNotifier(
    ref.watch(appointmentRepositoryProvider),
    ref.watch(locationRepositoryProvider),
    ref.watch(barbers_di.barberRepositoryProvider),
    ref.watch(services_di.serviceRepositoryProvider),
    ref.watch(brandRepositoryProvider),
    ref.watch(bookingTransactionProvider),
    isStaff: isStaff,
  )..load(appointmentId);
});

final editBookingNotifierProvider = StateNotifierProvider.family<
  EditBookingNotifier,
  EditBookingState?,
  String
>((ref, appointmentId) {
  return EditBookingNotifier(
    ref.watch(firebaseFirestoreProvider),
    ref.watch(appointmentRepositoryProvider),
    ref.watch(locationRepositoryProvider),
    ref.watch(barbers_di.barberRepositoryProvider),
    ref.watch(services_di.serviceRepositoryProvider),
    ref.watch(brandRepositoryProvider),
    ref.watch(bookingTransactionProvider),
  )..load(appointmentId);
});

/// Available time slots for edit booking (reschedule). Excludes current
/// appointment slot when same date for same-day reschedule.
final availableTimeSlotsForEditProvider =
    FutureProvider.family<List<TimeSlot>, String>((ref, appointmentId) async {
      final editState = ref.watch(editBookingNotifierProvider(appointmentId));
      if (editState == null || editState.selectedDate == null) {
        return [];
      }

      final calculateFreeSlots = ref.watch(calculateFreeSlotsProvider);
      final barberResult = await ref
          .watch(barbers_di.barberRepositoryProvider)
          .getById(editState.appointment.barberId);
      final barber = barberResult.fold<BarberEntity?>(
        (_) => null,
        (b) => b,
      );
      if (barber == null) return [];

      final brandResult = await ref
          .watch(brandRepositoryProvider)
          .getById(editState.appointment.brandId);
      final brand = brandResult.fold((_) => null, (b) => b);
      if (brand == null) return [];

      final locationResult = await ref
          .watch(locationRepositoryProvider)
          .getById(editState.appointment.locationId);
      final location = locationResult.fold(
        (_) => null,
        (l) => l,
      );
      if (location == null || location.workingHours.isEmpty) return [];

      return calculateFreeSlots.getFreeSlotsForBarber(
        barber: barber,
        location: location,
        date: editState.selectedDate!,
        slotIntervalMinutes: brand.slotInterval,
        serviceDurationMinutes: editState.serviceDurationMinutes,
        bufferTimeMinutes: brand.bufferTime,
        excludeAppointmentId: editState.appointment.appointmentId,
      );
    });

/// Auto-disposes when no listener (e.g. when user leaves booking page).
/// Next time booking is opened, a fresh state is created.
final bookingNotifierProvider =
    StateNotifierProvider.autoDispose<BookingNotifier, BookingState>((ref) {
      final flavor = ref.watch(flavorConfigProvider);
      final brandId = flavor.values.brandConfig.defaultBrandId;
      return BookingNotifier(
        ref.watch(barbers_di.barberRepositoryProvider),
        ref.watch(locationRepositoryProvider),
        brandId,
      );
    });

/// Provider for available time slots. Auto-disposes with booking notifier.
final availableTimeSlotsProvider = FutureProvider.autoDispose<List<TimeSlot>>((
  ref,
) async {
  final locationId = ref.watch(
    bookingNotifierProvider.select((s) => s.locationId),
  );
  final selectedDate = ref.watch(
    bookingNotifierProvider.select((s) => s.selectedDate),
  );
  final serviceDuration = ref.watch(
    bookingNotifierProvider.select((s) => s.selectedService?.durationMinutes),
  );
  final selectedBarber = ref.watch(
    bookingNotifierProvider.select((s) => s.selectedBarber),
  );

  if (locationId == null || selectedDate == null || serviceDuration == null) {
    return [];
  }

  final calculateFreeSlots = ref.watch(calculateFreeSlotsProvider);

  final flavor = ref.watch(flavorConfigProvider);
  final brandId = flavor.values.brandConfig.defaultBrandId;
  final brandResult = await ref.watch(brandRepositoryProvider).getById(brandId);
  final brand = brandResult.fold((_) => null, (b) => b);
  if (brand == null) return [];

  final locationResult = await ref
      .watch(locationRepositoryProvider)
      .getById(locationId);
  final location = locationResult.fold((_) => null, (l) => l);
  if (location == null || location.workingHours.isEmpty) return [];

  final date = selectedDate;
  final slotInterval = brand.slotInterval;

  final bufferTime = brand.bufferTime;

  if (selectedBarber != null) {
    return calculateFreeSlots.getFreeSlotsForBarber(
      barber: selectedBarber,
      location: location,
      date: date,
      slotIntervalMinutes: slotInterval,
      serviceDurationMinutes: serviceDuration,
      bufferTimeMinutes: bufferTime,
    );
  } else {
    final barbersResult = await ref
        .watch(barbers_di.barberRepositoryProvider)
        .getByLocationId(locationId);
    final barbers = barbersResult.fold(
      (_) => <BarberEntity>[],
      (list) => list.where((b) => b.active).toList(),
    );
    if (barbers.isEmpty) return [];

    return calculateFreeSlots.getFreeSlotsForAnyBarber(
      barbers: barbers,
      location: location,
      date: date,
      slotIntervalMinutes: slotInterval,
      serviceDurationMinutes: serviceDuration,
      bufferTimeMinutes: bufferTime,
    );
  }
});
