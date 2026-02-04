import 'package:barber/core/value_objects/working_hours.dart';
import 'package:equatable/equatable.dart';

/// Employee assigned to a specific location.
/// doc_id: barber_id
///
/// Link to auth: when [userId] is set, this barber record is linked to the
/// user who logs in (users/{userId}). Used to show "my" barber data when
/// a barber logs in. Set via Admin SDK when assigning barber role.
class BarberEntity extends Equatable {
  const BarberEntity({
    required this.barberId,
    required this.brandId,
    required this.locationId,
    required this.name,
    required this.photoUrl,
    required this.active,
    this.workingHoursOverride,
    this.userId,
  });

  final String barberId;
  final String brandId;
  final String locationId;
  final String name;
  final String photoUrl;
  final bool active;
  final WorkingHoursMap? workingHoursOverride;

  /// Firebase Auth UID of the user who logs in as this barber. Links barbers
  /// collection to users collection. Set when assigning barber role.
  final String? userId;

  @override
  List<Object?> get props => [
        barberId,
        brandId,
        locationId,
        name,
        photoUrl,
        active,
        workingHoursOverride,
        userId,
      ];
}
