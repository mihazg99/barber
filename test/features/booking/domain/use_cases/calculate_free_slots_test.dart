import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/booking/domain/entities/availability_entity.dart';
import 'package:barber/features/booking/domain/entities/booked_slot.dart';
import 'package:barber/features/booking/domain/repositories/availability_repository.dart';
import 'package:barber/features/booking/domain/use_cases/calculate_free_slots.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/time_off/domain/repositories/time_off_repository.dart';
import 'package:barber/features/time_off/domain/entities/time_off_entity.dart';

void main() {
  group('CalculateFreeSlots – working hours edge case', () {
    // Monday 13 April 2026
    final monday13April = DateTime(2026, 4, 13);

    late MockAvailabilityRepository availabilityRepo;
    late MockTimeOffRepository timeOffRepo;
    late LocationEntity location;
    late BarberEntity barberMarioGreen;

    setUp(() {
      availabilityRepo = MockAvailabilityRepository();
      timeOffRepo = MockTimeOffRepository();
      location = LocationEntity(
        locationId: 'loc-1',
        brandId: 'brand-1',
        name: 'Main',
        address: 'Address',
        latitude: 0,
        longitude: 0,
        phone: '',
        workingHours: {
          'mon': const DayWorkingHours(open: '08:00', close: '20:00'),
          'tue': const DayWorkingHours(open: '08:00', close: '20:00'),
          'wed': const DayWorkingHours(open: '08:00', close: '20:00'),
          'thu': const DayWorkingHours(open: '08:00', close: '20:00'),
          'fri': const DayWorkingHours(open: '08:00', close: '20:00'),
          'sat': const DayWorkingHours(open: '09:00', close: '17:00'),
          'sun': null,
        },
      );
    });

    test('when barber working hours are 09:00–16:30, 16:30 is NOT offered as slot (close is exclusive)', () async {
      // Professional later changes working hours to 09:00 - 16:30.
      // A slot starting at 16:30 would end at 17:00 (e.g. 30-min service), which is after close → must not be offered.
      barberMarioGreen = BarberEntity(
        barberId: 'mario-green',
        brandId: 'brand-1',
        locationId: 'loc-1',
        name: 'Mario Green',
        photoUrl: '',
        active: true,
        workingHoursOverride: {
          'mon': const DayWorkingHours(open: '09:00', close: '16:30'),
          'tue': const DayWorkingHours(open: '09:00', close: '16:30'),
          'wed': const DayWorkingHours(open: '09:00', close: '16:30'),
          'thu': const DayWorkingHours(open: '09:00', close: '16:30'),
          'fri': const DayWorkingHours(open: '09:00', close: '16:30'),
          'sat': const DayWorkingHours(open: '09:00', close: '16:30'),
          'sun': null,
        },
      );

      availabilityRepo.getResult = Right(null); // no existing bookings
      timeOffRepo.getByBarberIdAndDateResult = const Right([]);

      final useCase = CalculateFreeSlots(availabilityRepo, timeOffRepo);
      final slots = await useCase.getFreeSlotsForBarber(
        barber: barberMarioGreen,
        location: location,
        date: monday13April,
        slotIntervalMinutes: 30,
        serviceDurationMinutes: 30,
        bufferTimeMinutes: 5,
      );

      final times = slots.map((s) => s.time).toList();
      expect(times, isNot(contains('16:30')), reason: '16:30 must not be offered when close is 16:30 (service would end at 17:00)');
      expect(times, contains('16:00'), reason: '16:00 should be the last valid start for a 30-min service when close is 16:30');
    });

    test('user had booked 16:30 when hours were 09:00–18:00; after change to 09:00–16:30, 16:30 is still not offered for new bookings', () async {
      // Scenario: User books Monday 13.4 16:30 for Mario Green. Later professional changes hours to 09:00–16:30.
      // Existing appointment (16:30–17:00) remains in availability. New bookings must not get 16:30 (slot taken + after close).
      barberMarioGreen = BarberEntity(
        barberId: 'mario-green',
        brandId: 'brand-1',
        locationId: 'loc-1',
        name: 'Mario Green',
        photoUrl: '',
        active: true,
        workingHoursOverride: {
          'mon': const DayWorkingHours(open: '09:00', close: '16:30'),
          'tue': const DayWorkingHours(open: '09:00', close: '16:30'),
          'wed': const DayWorkingHours(open: '09:00', close: '16:30'),
          'thu': const DayWorkingHours(open: '09:00', close: '16:30'),
          'fri': const DayWorkingHours(open: '09:00', close: '16:30'),
          'sat': const DayWorkingHours(open: '09:00', close: '16:30'),
          'sun': null,
        },
      );

      final existingBookedSlot = BookedSlot(
        start: '16:30',
        end: '17:00',
        appointmentId: 'existing-appointment-id',
      );
      availabilityRepo.getResult = Right(AvailabilityEntity(
        docId: 'mario-green_2026-04-13',
        barberId: 'mario-green',
        locationId: 'loc-1',
        date: '2026-04-13',
        bookedSlots: [existingBookedSlot],
      ));
      timeOffRepo.getByBarberIdAndDateResult = const Right([]);

      final useCase = CalculateFreeSlots(availabilityRepo, timeOffRepo);
      final slots = await useCase.getFreeSlotsForBarber(
        barber: barberMarioGreen,
        location: location,
        date: monday13April,
        slotIntervalMinutes: 30,
        serviceDurationMinutes: 30,
        bufferTimeMinutes: 5,
      );

      final times = slots.map((s) => s.time).toList();
      expect(times, isNot(contains('16:30')), reason: '16:30 is both booked and past close 16:30');
      expect(times, contains('16:00'), reason: '16:00 can still be free if no booking there');
    });

    test('when barber had 09:00–18:00, 16:30 is offered (before hours change)', () async {
      barberMarioGreen = BarberEntity(
        barberId: 'mario-green',
        brandId: 'brand-1',
        locationId: 'loc-1',
        name: 'Mario Green',
        photoUrl: '',
        active: true,
        workingHoursOverride: {
          'mon': const DayWorkingHours(open: '09:00', close: '18:00'),
          'tue': const DayWorkingHours(open: '09:00', close: '18:00'),
          'wed': const DayWorkingHours(open: '09:00', close: '18:00'),
          'thu': const DayWorkingHours(open: '09:00', close: '18:00'),
          'fri': const DayWorkingHours(open: '09:00', close: '18:00'),
          'sat': const DayWorkingHours(open: '09:00', close: '18:00'),
          'sun': null,
        },
      );

      availabilityRepo.getResult = Right(null);
      timeOffRepo.getByBarberIdAndDateResult = const Right([]);

      final useCase = CalculateFreeSlots(availabilityRepo, timeOffRepo);
      final slots = await useCase.getFreeSlotsForBarber(
        barber: barberMarioGreen,
        location: location,
        date: monday13April,
        slotIntervalMinutes: 30,
        serviceDurationMinutes: 30,
        bufferTimeMinutes: 5,
      );

      final times = slots.map((s) => s.time).toList();
      expect(times, contains('16:30'), reason: 'With close 18:00, 16:30 is a valid start for 30-min service');
    });
  });
}

class MockAvailabilityRepository implements AvailabilityRepository {
  Either<Failure, AvailabilityEntity?> getResult = Right(null);

  @override
  Future<Either<Failure, AvailabilityEntity?>> get(String docId) async => getResult;

  @override
  Future<Either<Failure, void>> set(AvailabilityEntity entity) async => const Right(null);
}

class MockTimeOffRepository implements TimeOffRepository {
  Either<Failure, List<TimeOffEntity>> getByBarberIdAndDateResult = const Right([]);

  @override
  Future<Either<Failure, void>> create(TimeOffEntity entity) async => const Right(null);

  @override
  Future<Either<Failure, TimeOffEntity?>> getById(String timeOffId) async => const Right(null);

  @override
  Future<Either<Failure, List<TimeOffEntity>>> getByBarberId(String barberId) async => const Right([]);

  @override
  Future<Either<Failure, List<TimeOffEntity>>> getByBarberIdAndDate(String barberId, DateTime date) async =>
      getByBarberIdAndDateResult;

  @override
  Future<Either<Failure, void>> update(TimeOffEntity entity) async => const Right(null);

  @override
  Future<Either<Failure, void>> delete(String timeOffId) async => const Right(null);

  @override
  Stream<List<TimeOffEntity>> watchByBarberId(String barberId) => Stream.value([]);
}
