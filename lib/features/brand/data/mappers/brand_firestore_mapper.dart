import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [BrandEntity]. Keeps Firestore in data layer.
class BrandFirestoreMapper {
  static BrandEntity fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BrandEntity(
      brandId: doc.id,
      name: data['name'] as String? ?? '',
      isMultiLocation: data['is_multi_location'] as bool? ?? false,
      primaryColor: data['primary_color'] as String? ?? '#000000',
      logoUrl: data['logo_url'] as String? ?? '',
      contactEmail: data['contact_email'] as String? ?? '',
      slotInterval: (data['slot_interval'] as num?)?.toInt() ?? 30,
      bufferTime: (data['buffer_time'] as num?)?.toInt() ?? 0,
      cancelHoursMinimum: (data['cancel_hours_minimum'] as num?)?.toInt() ?? 0,
      loyaltyPointsMultiplier:
          (data['loyalty_points_multiplier'] as num?)?.toInt() ?? 10,
      requireSmsVerification:
          (data['require_sms_verification'] as bool?) ?? false,
      currency: data['currency'] as String? ?? 'EUR',
      fontFamily: data['font_family'] as String? ?? 'Inter',
      locale: data['locale'] as String? ?? 'hr',
      themeColors:
          (data['colors'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          const {},
    );
  }

  static Map<String, dynamic> toFirestore(BrandEntity entity) => {
    'name': entity.name,
    'is_multi_location': entity.isMultiLocation,
    'primary_color': entity.primaryColor,
    'logo_url': entity.logoUrl,
    'contact_email': entity.contactEmail,
    'slot_interval': entity.slotInterval,
    'buffer_time': entity.bufferTime,
    'cancel_hours_minimum': entity.cancelHoursMinimum,
    'loyalty_points_multiplier': entity.loyaltyPointsMultiplier,
    'require_sms_verification': entity.requireSmsVerification,
    'currency': entity.currency,
    'font_family': entity.fontFamily,
    'locale': entity.locale,
    'colors': entity.themeColors,
  };
}
