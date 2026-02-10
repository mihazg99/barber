import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand/data/mappers/brand_firestore_mapper.dart';

Future<String> createTestBrand() async {
  final firestore = FirebaseFirestore.instance;
  final brandId = 'test-brand-green';
  final locationId = 'green-location-1';

  // 1. Create Brand
  final brand = BrandEntity(
    brandId: brandId,
    name: 'Green Barber',
    isMultiLocation: false,
    primaryColor: '#00FF00', // Bright Green
    logoUrl: 'https://via.placeholder.com/150/00FF00/FFFFFF?text=Green',
    contactEmail: 'green@barber.com',
    slotInterval: 30,
    bufferTime: 5,
    cancelHoursMinimum: 24,
    loyaltyPointsMultiplier: 10,
    requireSmsVerification: false,
    currency: 'USD',
    fontFamily: 'Roboto',
    locale: 'en',
    themeColors: {
      'primary': '#00FF00', // Green
      'secondary': '#004400', // Dark Green
      'background': '#001100', // Very Dark Green
      'primary_text': '#FFFFFF',
      'secondary_text': '#AAFFAA',
      'caption_text': '#88AA88',
      'primary_white': '#FFFFFF',
      'hint_text': '#448844',
      'menu_background': '#002200',
      'navigation_background': '#001100', // Match background
      'border': '#003300',
      'error': '#FF4444',
    },
  );

  await firestore
      .collection('brands')
      .doc(brandId)
      .set(BrandFirestoreMapper.toFirestore(brand));

  // 2. Create Location
  await firestore.collection('locations').doc(locationId).set({
    'brand_id': brandId,
    'name': 'Green HQ',
    'address': '123 Green Street, Emerald City',
    'geo_point': const GeoPoint(45.8150, 15.9819), // Zagreb
    'phone': '+1234567890',
    'working_hours': {
      'mon': {'open': '09:00', 'close': '17:00', 'is_working': true},
      'tue': {'open': '09:00', 'close': '17:00', 'is_working': true},
      'wed': {'open': '09:00', 'close': '17:00', 'is_working': true},
      'thu': {'open': '09:00', 'close': '17:00', 'is_working': true},
      'fri': {'open': '09:00', 'close': '17:00', 'is_working': true},
      'sat': {'open': '10:00', 'close': '14:00', 'is_working': true},
      'sun': {'open': '00:00', 'close': '00:00', 'is_working': false},
    },
  });

  // 3. Create Barbers
  final barbers = [
    {
      'id': 'green-barber-1',
      'name': 'Mario Green',
      'email': 'mario@green.com',
      'bio': 'Master of the green fade.',
      'avatar_url': 'https://i.pravatar.cc/150?u=green1',
      'brand_id': brandId,
      'location_ids': [locationId],
    },
    {
      'id': 'green-barber-2',
      'name': 'Luigi Verde',
      'email': 'luigi@green.com',
      'bio': 'Specialist in eco-cuts.',
      'avatar_url': 'https://i.pravatar.cc/150?u=green2',
      'brand_id': brandId,
      'location_ids': [locationId],
    },
  ];

  for (final b in barbers) {
    await firestore.collection('barbers').doc(b['id'] as String).set(b);
  }

  // 4. Create Services
  final services = [
    {
      'id': 'green-service-1',
      'name': 'Standard Cut',
      'description': 'Classic cut with scissors and clippers.',
      'price': 25.0,
      'duration_minutes': 30,
      'brand_id': brandId,
    },
    {
      'id': 'green-service-2',
      'name': 'Beard Trim',
      'description': 'Shape and style your beard.',
      'price': 15.0,
      'duration_minutes': 15,
      'brand_id': brandId,
    },
    {
      'id': 'green-service-3',
      'name': 'Full Service',
      'description': 'Haircut + Beard + Wash.',
      'price': 35.0,
      'duration_minutes': 45,
      'brand_id': brandId,
    },
  ];

  for (final s in services) {
    await firestore.collection('services').doc(s['id'] as String).set(s);
  }

  // 5. Create Rewards
  final rewards = [
    {
      'id': 'green-reward-1',
      'title': 'Free Product',
      'description': 'Get a free hair wax.',
      'points_cost': 500,
      'brand_id': brandId,
      'image_url': 'https://placehold.co/600x400/003300/FFFFFF/png?text=Wax',
    },
    {
      'id': 'green-reward-2',
      'title': '50% Off Cut',
      'description': 'Half price on your next visit.',
      'points_cost': 300,
      'brand_id': brandId,
      'image_url': 'https://placehold.co/600x400/003300/FFFFFF/png?text=50%',
    },
  ];

  for (final r in rewards) {
    await firestore.collection('rewards').doc(r['id'] as String).set(r);
  }

  debugPrint('✅ Test Brand "Green Barber" Fully Seeded!');
  debugPrint('📷 QR Code Content: brand:$brandId');

  return brandId;
}
