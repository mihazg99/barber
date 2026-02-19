import 'package:equatable/equatable.dart';

/// Service offered by the brand.
/// doc_id: service_id
class ServiceEntity extends Equatable {
  const ServiceEntity({
    required this.serviceId,
    required this.brandId,
    required this.availableAtLocations,
    required this.name,
    required this.price,
    required this.durationMinutes,
    required this.description,
    this.category,
  });

  final String serviceId;
  final String brandId;
  final List<String> availableAtLocations;
  final String name;
  final num price;
  final int durationMinutes;
  final String description;
  final String? category;

  /// True if this service is offered at [locationId].
  /// Empty [availableAtLocations] means "all locations".
  bool isAvailableAt(String? locationId) {
    if (locationId == null) return true;
    if (availableAtLocations.isEmpty) return true;
    return availableAtLocations.contains(locationId);
  }

  @override
  List<Object?> get props => [
    serviceId,
    brandId,
    availableAtLocations,
    name,
    price,
    durationMinutes,
    description,
    category,
  ];
}
