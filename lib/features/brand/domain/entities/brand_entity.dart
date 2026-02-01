import 'package:equatable/equatable.dart';

/// Root configuration for each client (brand).
/// doc_id: brand_id (e.g. old-school-barber)
class BrandEntity extends Equatable {
  const BrandEntity({
    required this.brandId,
    required this.name,
    required this.isMultiLocation,
    required this.primaryColor,
    required this.logoUrl,
    required this.contactEmail,
    required this.slotInterval,
    required this.bufferTime,
  });

  final String brandId;
  final String name;
  final bool isMultiLocation;
  final String primaryColor; // Hex, e.g. "#0A0A0A"
  final String logoUrl;
  final String contactEmail;
  final int slotInterval; // minutes, e.g. 15 or 30
  final int bufferTime; // minutes between appointments

  @override
  List<Object?> get props => [
        brandId,
        name,
        isMultiLocation,
        primaryColor,
        logoUrl,
        contactEmail,
        slotInterval,
        bufferTime,
      ];
}
