import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/locations/domain/repositories/location_repository.dart';

class DashboardLocationsNotifier
    extends BaseNotifier<List<LocationEntity>, Failure> {
  DashboardLocationsNotifier(
    this._locationRepository,
    this._defaultBrandId,
  );

  final LocationRepository _locationRepository;
  final String _defaultBrandId;

  Future<void> load() async {
    if (_defaultBrandId.isEmpty) {
      setData([]);
      return;
    }
    await execute(
      () => _locationRepository.getByBrandId(_defaultBrandId),
      (f) => f.message,
    );
  }

  Future<void> create(LocationEntity location) async {
    setLoading();
    final result = await _locationRepository.set(location);
    result.fold(
      (f) => setError(f.message, f),
      (_) => load(),
    );
  }

  Future<void> update(LocationEntity location) async {
    setLoading();
    final result = await _locationRepository.set(location);
    result.fold(
      (f) => setError(f.message, f),
      (_) => load(),
    );
  }

  Future<void> delete(String locationId) async {
    setLoading();
    final result = await _locationRepository.delete(locationId);
    result.fold(
      (f) => setError(f.message, f),
      (_) => load(),
    );
  }
}
