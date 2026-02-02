import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';

/// Mock barbers and services for testing the home UI when Firestore is empty.
const String _brandId = 'mock-brand';
const String _locationId = 'mock-location';

final mockBarbersForHome = <BarberEntity>[
  const BarberEntity(
    barberId: 'mock-barber-1',
    brandId: _brandId,
    locationId: _locationId,
    name: 'Richard Anderson',
    photoUrl: '',
    active: true,
  ),
  const BarberEntity(
    barberId: 'mock-barber-2',
    brandId: _brandId,
    locationId: _locationId,
    name: 'James Wilson',
    photoUrl: '',
    active: true,
  ),
  const BarberEntity(
    barberId: 'mock-barber-3',
    brandId: _brandId,
    locationId: _locationId,
    name: 'Michael Brown',
    photoUrl: '',
    active: true,
  ),
];

final mockServicesForHome = <ServiceEntity>[
  const ServiceEntity(
    serviceId: 'mock-service-1',
    brandId: _brandId,
    availableAtLocations: [_locationId],
    name: 'Classic Haircut',
    price: 25,
    durationMinutes: 30,
    description: 'Traditional cut and finish',
  ),
  const ServiceEntity(
    serviceId: 'mock-service-2',
    brandId: _brandId,
    availableAtLocations: [_locationId],
    name: 'Beard Trim',
    price: 15,
    durationMinutes: 15,
    description: 'Shape and tidy your beard',
  ),
  const ServiceEntity(
    serviceId: 'mock-service-3',
    brandId: _brandId,
    availableAtLocations: [_locationId],
    name: 'Haircut + Beard',
    price: 35,
    durationMinutes: 45,
    description: 'Full grooming package',
  ),
  const ServiceEntity(
    serviceId: 'mock-service-4',
    brandId: _brandId,
    availableAtLocations: [_locationId],
    name: 'Kids Cut',
    price: 18,
    durationMinutes: 25,
    description: 'Haircut for children',
  ),
];
