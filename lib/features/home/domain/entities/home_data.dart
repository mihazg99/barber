import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:equatable/equatable.dart';

/// Data loaded for the home screen.
class HomeData extends Equatable {
  const HomeData({
    this.brand,
    this.locations = const [],
  });

  final BrandEntity? brand;
  final List<LocationEntity> locations;

  String get brandName => brand?.name ?? 'Barber';

  @override
  List<Object?> get props => [brand, locations];
}
