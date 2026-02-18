import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/barbers/domain/repositories/barber_repository.dart';

class DashboardBarbersNotifier
    extends BaseNotifier<List<BarberEntity>, Failure> {
  DashboardBarbersNotifier(
    this._barberRepository,
    this._defaultBrandId,
    this._version,
  );

  final BarberRepository _barberRepository;
  final String _defaultBrandId;
  final int? _version;

  Future<void> load() async {
    if (_defaultBrandId.isEmpty) {
      setData([]);
      return;
    }
    await execute(
      () => _barberRepository.getByBrandId(
        _defaultBrandId,
        version: _version,
      ),
      (f) => f.message,
    );
  }

  Future<void> save(BarberEntity entity) async {
    setLoading();
    final result = await _barberRepository.set(entity);
    result.fold(
      (f) => setError(f.message, f),
      (_) => load(),
    );
  }

  Future<void> delete(String barberId) async {
    setLoading();
    final result = await _barberRepository.delete(barberId);
    result.fold(
      (f) => setError(f.message, f),
      (_) => load(),
    );
  }
}
