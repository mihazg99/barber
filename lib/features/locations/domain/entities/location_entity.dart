import 'package:barber/core/value_objects/working_hours.dart';
import 'package:equatable/equatable.dart';

/// Specific shop belonging to a brand.
/// doc_id: location_id (e.g. zagreb-centar)
///
/// [closedDates] are holidays or other dates when the location is closed (YYYY-MM-DD).
/// Superadmin can disable/activate days via working hours (null = closed that weekday).
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
    this.closedDates = const [],
  });

  final String locationId;
  final String brandId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String phone;
  final WorkingHoursMap workingHours;
  /// Dates when the location is closed (e.g. holidays). Format: YYYY-MM-DD.
  final List<String> closedDates;

  /// True if the location is closed on [date] (holiday or other closed date).
  bool isClosedOnDate(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return closedDates.contains(key);
  }

  LocationEntity copyWith({
    String? locationId,
    String? brandId,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    WorkingHoursMap? workingHours,
    List<String>? closedDates,
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
        closedDates: closedDates ?? this.closedDates,
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
        closedDates,
      ];
}
