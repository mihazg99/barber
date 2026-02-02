import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/locations/domain/repositories/location_repository.dart';

class HomeNotifier extends BaseNotifier<HomeData, dynamic> {
  HomeNotifier(
    this._brandRepository,
    this._locationRepository,
    this._defaultBrandId,
  );

  final BrandRepository _brandRepository;
  final LocationRepository _locationRepository;
  final String _defaultBrandId;

  /// Load home data (brand + locations).
  /// If [defaultBrandId] is empty, emits [HomeData] with null brand and empty locations.
  Future<void> load() async {
    if (_defaultBrandId.isEmpty) {
      setData(const HomeData());
      return;
    }

    setLoading();
    final brandResult = await _brandRepository.getById(_defaultBrandId);
    final locationsResult = await _locationRepository.getByBrandId(
      _defaultBrandId,
    );

    final brand = brandResult.fold<BrandEntity?>((_) => null, (b) => b);
    final locations = locationsResult.fold<List<LocationEntity>>(
      (_) => [],
      (list) => list,
    );

    setData(HomeData(brand: brand, locations: locations));
  }

  Future<void> refresh() => load();
}
