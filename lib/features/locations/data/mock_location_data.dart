import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

/// Mock location for testing when Firestore is empty.
final mockLocation = LocationEntity(
  locationId: 'mock-location',
  brandId: 'mock-brand',
  name: 'Downtown Shop',
  address: '123 Main Street, City Center',
  latitude: 45.815399,
  longitude: 15.981919,
  phone: '+1-555-0123',
  workingHours: const {
    'mon': DayWorkingHours(open: '08:00', close: '20:00'),
    'tue': DayWorkingHours(open: '08:00', close: '20:00'),
    'wed': DayWorkingHours(open: '08:00', close: '20:00'),
    'thu': DayWorkingHours(open: '08:00', close: '20:00'),
    'fri': DayWorkingHours(open: '08:00', close: '21:00'),
    'sat': DayWorkingHours(open: '09:00', close: '17:00'),
    'sun': null, // Closed on Sunday
  },
);
