import 'package:barber/core/value_objects/working_hours.dart';
import 'package:equatable/equatable.dart';

/// Employee assigned to a specific location.
/// doc_id: barber_id
class BarberEntity extends Equatable {
  const BarberEntity({
    required this.barberId,
    required this.brandId,
    required this.locationId,
    required this.name,
    required this.photoUrl,
    required this.active,
    this.workingHoursOverride,
  });

  final String barberId;
  final String brandId;
  final String locationId;
  final String name;
  final String photoUrl;
  final bool active;
  final WorkingHoursMap? workingHoursOverride;

  @override
  List<Object?> get props => [
        barberId,
        brandId,
        locationId,
        name,
        photoUrl,
        active,
        workingHoursOverride,
      ];
}
