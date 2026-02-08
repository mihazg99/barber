import 'dart:async';

import 'package:barber/core/state/base_notifier.dart';

import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/booking/domain/repositories/appointment_repository.dart';

class UpcomingAppointmentNotifier
    extends BaseNotifier<AppointmentEntity?, dynamic> {
  UpcomingAppointmentNotifier(
    this._repository,
    this._userId,
  ) {
    _startListening();
  }

  final AppointmentRepository _repository;
  final String _userId;

  StreamSubscription<String?>? _activeIdSubscription;
  StreamSubscription<AppointmentEntity?>? _appointmentSubscription;

  void _startListening() {
    if (_userId.isEmpty) {
      setData(null);
      return;
    }
    setLoading();
    _activeIdSubscription = _repository
        .watchActiveAppointmentId(_userId)
        .listen(
          (activeId) {
            _appointmentSubscription?.cancel();
            _appointmentSubscription = null;

            if (activeId == null || activeId.isEmpty) {
              setData(null);
              return;
            }

            setLoading();
            _appointmentSubscription = _repository
                .watchAppointment(activeId)
                .listen(
                  (appointment) {
                    if (appointment == null) {
                      setData(null);
                      return;
                    }

                    if (appointment.status != AppointmentStatus.scheduled) {
                      setData(null);
                      return;
                    }

                    if (!appointment.startTime.isAfter(DateTime.now())) {
                      setData(null);
                      return;
                    }

                    setData(appointment);
                  },
                  onError: (e) {
                    setError(e.toString(), e);
                  },
                );
          },
          onError: (e) {
            setError(e.toString(), e);
          },
        );
  }

  @override
  void dispose() {
    _activeIdSubscription?.cancel();
    _appointmentSubscription?.cancel();
    super.dispose();
  }
}
