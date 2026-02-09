import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
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

  String? _loadingBrandId;

  /// Load home data (brand + locations). Pass [cachedBrand] to avoid a duplicate brand read when already loaded (e.g. from [defaultBrandProvider]).
  /// No-op if we already have data for the same brand or a load is already in progress for this brand (avoids duplicate reads).
  Future<void> load({BrandEntity? cachedBrand}) async {
    if (_defaultBrandId.isEmpty) {
      setData(HomeData(brand: null, locations: const []));
      return;
    }

    final current = state;
    if (current is BaseData<HomeData>) {
      final existingBrandId = current.data.brand?.brandId;
      if (existingBrandId == _defaultBrandId) return;
    }

    if (_loadingBrandId == _defaultBrandId) return;

    _loadingBrandId = _defaultBrandId;
    setLoading();
    BrandEntity? brand = cachedBrand;
    if (brand == null) {
      final brandResult = await _brandRepository.getById(_defaultBrandId);
      brand = brandResult.fold((_) => null, (b) => b);
      if (brand == null) {
        _loadingBrandId = null;
        setError('Failed to load brand', null);
        return;
      }
    }

    final locationsResult = await _locationRepository.getByBrandId(
      _defaultBrandId,
    );
    _loadingBrandId = null;
    locationsResult.fold(
      (f) => setError(f.message, f),
      (locations) => setData(HomeData(brand: brand, locations: locations)),
    );
  }

  Future<void> refresh({BrandEntity? cachedBrand}) => load(cachedBrand: cachedBrand);
}
