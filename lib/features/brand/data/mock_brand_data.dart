import 'package:barber/features/brand/domain/entities/brand_entity.dart';

/// Mock brand for testing when Firestore is empty.
const mockBrand = BrandEntity(
  brandId: 'mock-brand',
  name: 'Demo Barbershop',
  isMultiLocation: false,
  primaryColor: '#0A0A0A',
  logoUrl: 'https://zoyya.com/api/kingsman-barbershop/avatar/DqvPV43gybo9W98joDhER.png',
  contactEmail: 'contact@demobarbershop.com',
  slotInterval: 15, // 15-minute slots (also supports 30 when set in Firestore)
  bufferTime: 0, // no buffer between appointments
);
