import 'package:flutter/foundation.dart';

import 'package:barber/features/booking/domain/entities/booked_slot.dart';
import 'package:barber/features/booking/domain/entities/time_slot.dart';
import 'package:barber/features/booking/domain/repositories/availability_repository.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

/// Calculates free time slots for a barber on a given date.
class CalculateFreeSlots {
  const CalculateFreeSlots(this._availabilityRepository);

  final AvailabilityRepository _availabilityRepository;

  /// Get free slots for a single barber on a date.
  /// [bufferTimeMinutes] is the gap after each appointment before the next can start.
  Future<List<TimeSlot>> getFreeSlotsForBarber({
    required BarberEntity barber,
    required LocationEntity location,
    required DateTime date,
    required int slotIntervalMinutes,
    required int serviceDurationMinutes,
    required int bufferTimeMinutes,
  }) async {
    final dateStr = _formatDate(date);
    final docId = '${barber.barberId}_$dateStr';

    // Get working hours for the weekday
    final weekday = _getWeekdayKey(date);
    final workingHoursMap = barber.workingHoursOverride ?? location.workingHours;
    final dayHours = workingHoursMap[weekday];

    if (kDebugMode) {
      print('🔍 [Availability] ${barber.name} $dateStr ($weekday) '
          '${dayHours?.open ?? 'CLOSED'}-${dayHours?.close ?? 'CLOSED'} '
          'interval=${slotIntervalMinutes}min duration=${serviceDurationMinutes}min buffer=${bufferTimeMinutes}min');
    }

    if (dayHours == null) {
      if (kDebugMode) print('  ❌ No working hours for $weekday');
      return []; // Closed on this day
    }

    // Fetch availability (booked slots)
    final availabilityResult = await _availabilityRepository.get(docId);
    final bookedSlots = availabilityResult.fold(
      (_) => <BookedSlot>[],
      (availability) => availability?.bookedSlots ?? [],
    );

    // Generate candidate start times: fixed interval (e.g. 08:00, 08:15...) plus
    // "in-between" times right after each booking (booked.end + buffer), so e.g.
    // a 25-min service at 08:15 ends 08:40 → we offer 08:45 (15-min grid) but also
    // need to offer 08:40 when a 35-min ends at 08:35 (next start 08:40).
    final allSlots = _generateCandidateStartTimes(
      open: dayHours.open,
      close: dayHours.close,
      slotIntervalMinutes: slotIntervalMinutes,
      serviceDurationMinutes: serviceDurationMinutes,
      bufferTimeMinutes: bufferTimeMinutes,
      bookedSlots: bookedSlots,
    );

    // Filter out slots that overlap existing bookings or don't fit
    final freeSlots = <TimeSlot>[];
    for (final slotTime in allSlots) {
      if (_isSlotAvailable(
        slotTime,
        serviceDurationMinutes,
        bufferTimeMinutes,
        dayHours.close,
        bookedSlots,
      )) {
        freeSlots.add(TimeSlot(time: slotTime, barberId: barber.barberId));
      }
    }

    if (kDebugMode) {
      print('  📊 Slots: ${allSlots.length} candidates, ${bookedSlots.length} booked, ${freeSlots.length} free');
      if (freeSlots.isEmpty && allSlots.isNotEmpty) {
        print('  ⚠️  All slots filtered out (service too long or all booked)');
      }
    }

    return freeSlots;
  }

  /// Get union of free slots for multiple barbers ("Any Barber").
  Future<List<TimeSlot>> getFreeSlotsForAnyBarber({
    required List<BarberEntity> barbers,
    required LocationEntity location,
    required DateTime date,
    required int slotIntervalMinutes,
    required int serviceDurationMinutes,
    required int bufferTimeMinutes,
  }) async {
    final allSlots = <String, String>{}; // time -> first barberId

    for (final barber in barbers) {
      final barberSlots = await getFreeSlotsForBarber(
        barber: barber,
        location: location,
        date: date,
        slotIntervalMinutes: slotIntervalMinutes,
        serviceDurationMinutes: serviceDurationMinutes,
        bufferTimeMinutes: bufferTimeMinutes,
      );

      for (final slot in barberSlots) {
        if (!allSlots.containsKey(slot.time)) {
          allSlots[slot.time] = slot.barberId;
        }
      }
    }

    // Convert to sorted list
    final times = allSlots.keys.toList()..sort();
    return times.map((time) => TimeSlot(time: time, barberId: allSlots[time]!)).toList();
  }

  /// Builds candidate start times: interval-based (08:00, 08:15, ...) plus
  /// the first possible start after each booking (booked.end + buffer), so
  /// services that don't align to the interval (e.g. 25 min) still get the
  /// next slot right after the previous one (e.g. 08:40 after 08:15–08:40).
  List<String> _generateCandidateStartTimes({
    required String open,
    required String close,
    required int slotIntervalMinutes,
    required int serviceDurationMinutes,
    required int bufferTimeMinutes,
    required List<BookedSlot> bookedSlots,
  }) {
    final openMinutes = _timeToMinutes(open);
    final closeMinutes = _timeToMinutes(close);
    final candidates = <int>{};

    // Interval-based times (e.g. every 15 min)
    var current = openMinutes;
    while (current < closeMinutes) {
      candidates.add(current);
      current += slotIntervalMinutes;
    }

    // In-between: first possible start after each booked slot (end + buffer)
    for (final booked in bookedSlots) {
      final bookedEnd = _timeToMinutes(booked.end);
      final nextStart = bookedEnd + bufferTimeMinutes;
      if (nextStart >= openMinutes && nextStart + serviceDurationMinutes <= closeMinutes) {
        candidates.add(nextStart);
      }
    }

    final list = candidates.toList()..sort();
    return list.map(_minutesToTime).toList();
  }

  /// Check if a slot is available (not booked, fits service duration, respects buffer).
  /// Each booked slot blocks until [booked.end + bufferTimeMinutes] so the next appointment cannot start until after the buffer.
  bool _isSlotAvailable(
    String slotTime,
    int serviceDurationMinutes,
    int bufferTimeMinutes,
    String closeTime,
    List<BookedSlot> bookedSlots,
  ) {
    final slotStart = _timeToMinutes(slotTime);
    final slotEnd = slotStart + serviceDurationMinutes;
    final closeMinutes = _timeToMinutes(closeTime);

    // Check if service fits before closing
    if (slotEnd > closeMinutes) return false;

    // Check if overlaps any booked slot (booked slot blocks until end + buffer)
    for (final booked in bookedSlots) {
      final bookedStart = _timeToMinutes(booked.start);
      final bookedEnd = _timeToMinutes(booked.end);
      final blockedUntil = bookedEnd + bufferTimeMinutes;

      // Next appointment cannot start until after buffer: treat blocked range as [bookedStart, blockedUntil]
      if (slotStart < blockedUntil && slotEnd > bookedStart) {
        return false;
      }
    }

    return true;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  String _minutesToTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getWeekdayKey(DateTime date) {
    const keys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return keys[date.weekday - 1];
  }
}
