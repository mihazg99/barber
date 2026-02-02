import 'package:barber/features/booking/domain/entities/availability_entity.dart';
import 'package:barber/features/booking/domain/repositories/availability_repository.dart';

/// Helper to seed/initialize availability documents for testing.
/// 
/// **Important**: Availability documents are OPTIONAL. If they don't exist,
/// the system assumes all slots are free (based on working hours).
/// 
/// Only create availability documents when:
/// 1. Testing with pre-booked slots
/// 2. Seeding the database for production
/// 
/// Example usage in a test/debug screen:
/// ```dart
/// final seeder = ref.read(seedAvailabilityProvider);
/// await seeder.seedEmptyAvailability(
///   barberId: 'barber_123',
///   locationId: 'location_456',
///   date: DateTime.now(),
/// );
/// ```
class SeedAvailability {
  const SeedAvailability(this._availabilityRepository);

  final AvailabilityRepository _availabilityRepository;

  /// Create an empty availability document (all slots free).
  Future<void> seedEmptyAvailability({
    required String barberId,
    required String locationId,
    required DateTime date,
  }) async {
    final dateStr = _formatDate(date);
    final docId = '${barberId}_$dateStr';

    final availability = AvailabilityEntity(
      docId: docId,
      barberId: barberId,
      locationId: locationId,
      date: dateStr,
      bookedSlots: [], // Empty = all slots free
    );

    await _availabilityRepository.set(availability);
  }

  /// Seed multiple days for a barber (useful for testing).
  Future<void> seedBarberAvailabilityForDays({
    required String barberId,
    required String locationId,
    required int daysAhead,
  }) async {
    final today = DateTime.now();
    for (var i = 0; i < daysAhead; i++) {
      final date = DateTime(today.year, today.month, today.day).add(Duration(days: i));
      await seedEmptyAvailability(
        barberId: barberId,
        locationId: locationId,
        date: date,
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
