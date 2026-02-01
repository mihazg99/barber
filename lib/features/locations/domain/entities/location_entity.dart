import 'package:barber/core/value_objects/working_hours.dart';
import 'package:equatable/equatable.dart';

/// Specific shop belonging to a brand.
/// doc_id: location_id (e.g. zagreb-centar)
class LocationEntity extends Equatable {
  const LocationEntity({
    required this.locationId,
    required this.brandId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.workingHours,
  });

  final String locationId;
  final String brandId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final WorkingHoursMap workingHours;

  @override
  List<Object?> get props => [
        locationId,
        brandId,
        name,
        address,
        latitude,
        longitude,
        phone,
        workingHours,
      ];
}
