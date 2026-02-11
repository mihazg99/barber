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
    print('[HomeNotifier] load() called with brandId: $_defaultBrandId');
    if (_defaultBrandId.isEmpty) {
      print('[HomeNotifier] Empty brandId, setting empty data');
      setData(HomeData(brand: null, locations: const []));
      return;
    }

    final current = state;
    if (current is BaseData<HomeData>) {
      final existingBrandId = current.data.brand?.brandId;
      if (existingBrandId == _defaultBrandId) {
        print('[HomeNotifier] Already have data for this brand, skipping');
        return;
      }
    }

    if (_loadingBrandId == _defaultBrandId) {
      print('[HomeNotifier] Already loading this brand, skipping');
      return;
    }

    _loadingBrandId = _defaultBrandId;
    setLoading();
    BrandEntity? brand = cachedBrand;
    if (brand == null) {
      print('[HomeNotifier] Loading brand from repository');
      final brandResult = await _brandRepository.getById(_defaultBrandId);
      if (!mounted) return;
      brand = brandResult.fold((_) => null, (b) => b);
      if (brand == null) {
        _loadingBrandId = null;
        setError('Failed to load brand', null);
        return;
      }
    } else {
      print('[HomeNotifier] Using cached brand: ${brand.name}');
    }

    print('[HomeNotifier] Loading locations for brand: ${brand.brandId}');
    final locationsResult = await _locationRepository.getByBrandId(
      _defaultBrandId,
    );
    _loadingBrandId = null;

    if (!mounted) return;

    locationsResult.fold(
      (f) {
        print('[HomeNotifier] Error loading locations: ${f.message}');
        setError(f.message, f);
      },
      (locations) {
        print('[HomeNotifier] Loaded ${locations.length} locations');
        setData(HomeData(brand: brand, locations: locations));
      },
    );
  }

  Future<void> refresh({BrandEntity? cachedBrand}) =>
      load(cachedBrand: cachedBrand);
}
