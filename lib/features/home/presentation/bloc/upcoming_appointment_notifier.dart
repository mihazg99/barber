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

  StreamSubscription<List<AppointmentEntity>>? _appointmentsSubscription;

  void _startListening() {
    if (_userId.isEmpty) {
      setData(null);
      return;
    }
    setLoading();
    _appointmentsSubscription = _repository
        .watchUpcomingAppointmentsForUser(_userId)
        .listen(
          (appointments) {
            if (appointments.isEmpty) {
              setData(null);
              return;
            }
            // The query filters for scheduled status.
            // We must filter for start_time >= now and order by start_time client-side.
            final now = DateTime.now();
            final upcoming =
                appointments.where((a) {
                  return a.status == AppointmentStatus.scheduled &&
                      a.endTime.isAfter(now);
                }).toList();

            if (upcoming.isEmpty) {
              setData(null);
            } else {
              upcoming.sort((a, b) => a.startTime.compareTo(b.startTime));
              setData(upcoming.first);
            }
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
