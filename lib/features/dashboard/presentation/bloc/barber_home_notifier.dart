import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/state/base_notifier.dart';

/// Payload for barber home screen. Extend with today's appointments when API exists.
class BarberHomeData {
  const BarberHomeData();

  /// Placeholder for future: today's appointment count or next appointment.
  int get todayAppointmentCount => 0;
}

/// Notifier for barber dashboard home tab. AutoDispose so state is fresh when re-entering.
/// Currently holds minimal data; can load today's appointments when repository supports it.
class BarberHomeNotifier extends BaseNotifier<BarberHomeData, Failure> {
  BarberHomeNotifier() {
    setData(const BarberHomeData());
  }

  /// Refresh home data. No-op until we add getByBarberIdForDate to appointment repo.
  Future<void> load() async {
    setData(const BarberHomeData());
  }
}
