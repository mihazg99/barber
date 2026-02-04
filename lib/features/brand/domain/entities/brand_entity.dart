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
    this.cancelHoursMinimum = 0,
  });

  final String brandId;
  final String name;
  final bool isMultiLocation;
  final String primaryColor; // Hex, e.g. "#0A0A0A"
  final String logoUrl;
  final String contactEmail;
  final int slotInterval; // minutes, e.g. 15 or 30
  final int bufferTime; // minutes between appointments
  /// Minimum hours before appointment that cancellation is allowed. E.g. 48 = user
  /// must cancel at least 48h before. 0 = allow cancel anytime.
  final int cancelHoursMinimum;

  BrandEntity copyWith({
    String? brandId,
    String? name,
    bool? isMultiLocation,
    String? primaryColor,
    String? logoUrl,
    String? contactEmail,
    int? slotInterval,
    int? bufferTime,
    int? cancelHoursMinimum,
  }) =>
      BrandEntity(
        brandId: brandId ?? this.brandId,
        name: name ?? this.name,
        isMultiLocation: isMultiLocation ?? this.isMultiLocation,
        primaryColor: primaryColor ?? this.primaryColor,
        logoUrl: logoUrl ?? this.logoUrl,
        contactEmail: contactEmail ?? this.contactEmail,
        slotInterval: slotInterval ?? this.slotInterval,
        bufferTime: bufferTime ?? this.bufferTime,
        cancelHoursMinimum: cancelHoursMinimum ?? this.cancelHoursMinimum,
      );

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
        cancelHoursMinimum,
      ];
}
