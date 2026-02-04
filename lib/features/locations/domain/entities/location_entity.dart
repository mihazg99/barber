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

  LocationEntity copyWith({
    String? locationId,
    String? brandId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    WorkingHoursMap? workingHours,
  }) =>
      LocationEntity(
        locationId: locationId ?? this.locationId,
        brandId: brandId ?? this.brandId,
        name: name ?? this.name,
        address: address ?? this.address,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        phone: phone ?? this.phone,
        workingHours: workingHours ?? this.workingHours,
      );

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
