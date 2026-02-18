import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';

class DashboardBrandNotifier extends BaseNotifier<BrandEntity?, Failure> {
  DashboardBrandNotifier(
    this._brandRepository,
    this._brandId, {
    BrandEntity? cachedBrand,
  }) {
    if (cachedBrand != null && cachedBrand.brandId == _brandId) {
      setData(cachedBrand);
    } else if (_brandId.isNotEmpty) {
      load();
    }
  }

  final BrandRepository _brandRepository;
  final String _brandId;

  /// Load brand. Pass [cachedBrand] to avoid duplicate Firestore read (e.g. from defaultBrandProvider).
  Future<void> load({BrandEntity? cachedBrand}) async {
    if (_brandId.isEmpty) {
      setData(null);
      return;
    }
    if (cachedBrand != null && cachedBrand.brandId == _brandId) {
      setData(cachedBrand);
      return;
    }
    await execute(
      () => _brandRepository.getById(_brandId),
      (f) => f.message,
    );
  }

  Future<void> save(BrandEntity brand) async {
    setLoading();
    final result = await _brandRepository.set(brand);
    result.fold(
      (f) => setError(f.message, f),
      (_) => setData(brand),
    );
  }
}
