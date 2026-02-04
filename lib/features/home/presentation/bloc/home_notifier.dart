import 'package:barber/core/state/base_notifier.dart';
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

  /// Load home data (brand + locations) from Firebase.
  Future<void> load() async {
    if (_defaultBrandId.isEmpty) {
      setData(HomeData(brand: null, locations: const []));
      return;
    }

    setLoading();
    final brandResult = await _brandRepository.getById(_defaultBrandId);
    final locationsResult = await _locationRepository.getByBrandId(
      _defaultBrandId,
    );

    brandResult.fold(
      (f) => setError(f.message, f),
      (brand) {
        locationsResult.fold(
          (f) => setError(f.message, f),
          (locations) => setData(HomeData(brand: brand, locations: locations)),
        );
      },
    );
  }

  Future<void> refresh() => load();
}
