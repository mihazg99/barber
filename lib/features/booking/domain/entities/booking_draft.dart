import 'dart:convert';

/// Minimal serializable booking selection for guest persistence.
/// Restored after sign-in so the user can confirm without re-selecting.
class BookingDraft {
  const BookingDraft({
    required this.brandId,
    required this.locationId,
    required this.serviceId,
    this.barberId,
    required this.dateIso,
    required this.timeSlot,
    this.timeSlotBarberId,
  });

  final String brandId;
  final String locationId;
  final String serviceId;
  final String? barberId;
  final String dateIso;
  final String timeSlot;
  final String? timeSlotBarberId;

  Map<String, dynamic> toJson() => {
    'brandId': brandId,
    'locationId': locationId,
    'serviceId': serviceId,
    'barberId': barberId,
    'dateIso': dateIso,
    'timeSlot': timeSlot,
    'timeSlotBarberId': timeSlotBarberId,
  };

  static BookingDraft? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final brandId = json['brandId'] as String?;
    final locationId = json['locationId'] as String?;
    final serviceId = json['serviceId'] as String?;
    final dateIso = json['dateIso'] as String?;
    final timeSlot = json['timeSlot'] as String?;
    if (brandId == null ||
        locationId == null ||
        serviceId == null ||
        dateIso == null ||
        timeSlot == null)
      return null;
    return BookingDraft(
      brandId: brandId,
      locationId: locationId,
      serviceId: serviceId,
      barberId: json['barberId'] as String?,
      dateIso: dateIso,
      timeSlot: timeSlot,
      timeSlotBarberId: json['timeSlotBarberId'] as String?,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static BookingDraft? fromJsonString(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final map = jsonDecode(s) as Map<String, dynamic>?;
      return fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
