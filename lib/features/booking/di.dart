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
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/barbers/di.dart' as barbers_di;
import 'package:barber/features/locations/di.dart';
import 'package:barber/features/locations/data/mock_location_data.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/brand/data/mock_brand_data.dart';
import 'package:barber/features/home/data/mock_home_data.dart';
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
  return CalculateFreeSlots(ref.watch(availabilityRepositoryProvider));
});

final bookingNotifierProvider =
    StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  final flavor = ref.watch(flavorConfigProvider);
  final brandId = flavor.values.brandConfig.defaultBrandId;
  return BookingNotifier(
    ref.watch(barbers_di.barberRepositoryProvider),
    ref.watch(locationRepositoryProvider),
    brandId,
  );
});

/// Provider for available time slots. Depends only on slot query (location, date, service, barber)
/// so that selecting a time slot does not trigger a refetch.
final availableTimeSlotsProvider = FutureProvider<List<TimeSlot>>((ref) async {
  final locationId = ref.watch(bookingNotifierProvider.select((s) => s.locationId));
  final selectedDate = ref.watch(bookingNotifierProvider.select((s) => s.selectedDate));
  final serviceDuration = ref.watch(
    bookingNotifierProvider.select((s) => s.selectedService?.durationMinutes),
  );
  final selectedBarber = ref.watch(bookingNotifierProvider.select((s) => s.selectedBarber));

  if (locationId == null || selectedDate == null || serviceDuration == null) {
    return [];
  }

  final calculateFreeSlots = ref.watch(calculateFreeSlotsProvider);

  // Get brand for slot interval (use mock as fallback)
  final flavor = ref.watch(flavorConfigProvider);
  final brandId = flavor.values.brandConfig.defaultBrandId;
  final brandResult = await ref.watch(brandRepositoryProvider).getById(brandId);
  final brand = brandResult.fold(
    (_) => mockBrand,
    (b) => b ?? mockBrand,
  );

  // Get location for working hours (use mock as fallback)
  final locationResult =
      await ref.watch(locationRepositoryProvider).getById(locationId);
  var location = locationResult.fold(
    (_) => mockLocation,
    (l) => l ?? mockLocation,
  );
  // If Firestore location has no working_hours, slots would be empty; use default hours.
  if (location.workingHours.isEmpty) {
    location = LocationEntity(
      locationId: location.locationId,
      brandId: location.brandId,
      name: location.name,
      address: location.address,
      latitude: location.latitude,
      longitude: location.longitude,
      phone: location.phone,
      workingHours: mockLocation.workingHours,
    );
  }

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
    // Same barber source as booking UI: Firestore by location, then mock fallback
    var barbers = await ref
        .watch(barbers_di.barberRepositoryProvider)
        .getByLocationId(locationId)
        .then((result) => result.fold(
              (_) => <BarberEntity>[],
              (list) => list.where((b) => b.active).toList(),
            ));
    if (barbers.isEmpty) {
      barbers = mockBarbersForHome
          .where((b) => b.locationId == locationId)
          .toList();
    }
    if (barbers.isEmpty) {
      barbers = mockBarbersForHome;
    }

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
