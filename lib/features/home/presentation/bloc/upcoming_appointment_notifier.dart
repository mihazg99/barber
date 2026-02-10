import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/state/base_notifier.dart';

import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/booking/domain/repositories/appointment_repository.dart';

class UpcomingAppointmentNotifier
    extends BaseNotifier<AppointmentEntity?, dynamic> {
  UpcomingAppointmentNotifier(
    this._repository,
    this._userId,
    this._brandId,
  ) {
    _startListening();
  }

  final AppointmentRepository _repository;
  final String _userId;
  final String _brandId;

  StreamSubscription<Either<Failure, AppointmentEntity?>>?
  _appointmentsSubscription;

  void _startListening() {
    if (_userId.isEmpty || _brandId.isEmpty) {
      setData(null);
      return;
    }
    setLoading();
    _appointmentsSubscription = _repository
        .watchUpcomingAppointmentsForUser(_userId, _brandId)
        .listen(
          (result) {
            result.fold(
              (failure) => setError(failure.message, failure),
              (appointment) => setData(appointment),
            );
          },
          onError: (e) {
            setError(e.toString(), e);
          },
        );
  }

  @override
  void dispose() {
    _appointmentsSubscription?.cancel();
    super.dispose();
  }
}
