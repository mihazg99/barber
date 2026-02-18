import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:barber/features/services/domain/repositories/service_repository.dart';

class DashboardServicesNotifier
    extends BaseNotifier<List<ServiceEntity>, Failure> {
  DashboardServicesNotifier(
    this._serviceRepository,
    this._defaultBrandId,
    this._version,
  );

  final ServiceRepository _serviceRepository;
  final String _defaultBrandId;
  final int? _version;

  Future<void> load() async {
    if (_defaultBrandId.isEmpty) {
      setData([]);
      return;
    }
    await execute(
      () => _serviceRepository.getByBrandId(
        _defaultBrandId,
        version: _version,
      ),
      (f) => f.message,
    );
  }

  Future<void> save(ServiceEntity entity) async {
    setLoading();
    final result = await _serviceRepository.set(entity);
    result.fold(
      (f) => setError(f.message, f),
      (_) => load(),
    );
  }

  Future<void> delete(String serviceId) async {
    setLoading();
    final result = await _serviceRepository.delete(serviceId);
    result.fold(
      (f) => setError(f.message, f),
      (_) => load(),
    );
  }
}
