import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/barbers/domain/repositories/barber_repository.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:barber/features/booking/data/services/booking_transaction.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/booking/domain/repositories/appointment_repository.dart';
import 'package:barber/features/locations/domain/repositories/location_repository.dart';
import 'package:barber/features/services/domain/repositories/service_repository.dart';

/// View model for the manage booking page.
class ManageBookingData {
  const ManageBookingData({
    required this.appointment,
    this.locationName,
    this.barberName,
    this.serviceNames = const [],
    this.canCancel = true,
    this.cancelHoursRequired,
  });

  final AppointmentEntity appointment;
  final String? locationName;
  final String? barberName;
  final List<String> serviceNames;

  /// True if user can cancel (within brand's cancel window).
  final bool canCancel;

  /// When [canCancel] is false: minimum hours before appointment required to cancel.
  final int? cancelHoursRequired;
}

class ManageBookingNotifier extends BaseNotifier<ManageBookingData, dynamic> {
  ManageBookingNotifier(
    this._appointmentRepository,
    this._locationRepository,
    this._barberRepository,
    this._serviceRepository,
    this._brandRepository,
    this._bookingTransaction,
  );

  final AppointmentRepository _appointmentRepository;
  final LocationRepository _locationRepository;
  final BarberRepository _barberRepository;
  final ServiceRepository _serviceRepository;
  final BrandRepository _brandRepository;
  final BookingTransaction _bookingTransaction;

  /// Loads appointment and related display data from Firebase.
  Future<void> load(String appointmentId) async {
    setLoading();
    final apptResult = await _appointmentRepository.getById(appointmentId);
    apptResult.fold(
      (f) => setError(f.message, f),
      (appointment) async {
        final appt = appointment;
        if (appt == null) {
          setError('Appointment not found', null);
          return;
        }
        if (appt.status != AppointmentStatus.scheduled) {
          setError('This appointment can no longer be managed', null);
          return;
        }

        final locationResult = await _locationRepository.getById(
          appt.locationId,
        );
        final barberResult = await _barberRepository.getById(appt.barberId);
        final brandResult = await _brandRepository.getById(appt.brandId);
        var serviceNames = <String>[];
        for (final sid in appt.serviceIds) {
          final sr = await _serviceRepository.getById(sid);
          sr.fold(
            (_) => null,
            (s) => s != null ? serviceNames.add(s.name) : null,
          );
        }
        if (serviceNames.isEmpty) {
          serviceNames =
              appt.serviceIds.map((id) => 'Service ($id)').toList();
        }

        final locationName = locationResult.fold(
          (_) => 'Unknown',
          (l) => l?.name ?? 'Unknown',
        );
        final barberName = barberResult.fold(
          (_) => 'Unknown',
          (b) => b?.name ?? 'Unknown',
        );
        final brand = brandResult.fold((_) => null, (b) => b);
        final cancelHoursMinimum = brand?.cancelHoursMinimum ?? 0;
        final (canCancel, cancelHoursRequired) = _computeCancelPolicy(
          appt.startTime,
          cancelHoursMinimum,
        );

        setData(
          ManageBookingData(
            appointment: appt,
            locationName: locationName,
            barberName: barberName,
            serviceNames: serviceNames,
            canCancel: canCancel,
            cancelHoursRequired: cancelHoursRequired,
          ),
        );
      },
    );
  }

  static (bool canCancel, int? hoursRequired) _computeCancelPolicy(
    DateTime appointmentStart,
    int cancelHoursMinimum,
  ) {
    if (cancelHoursMinimum <= 0) return (true, null);
    final hoursUntil = appointmentStart.difference(DateTime.now()).inHours;
    if (hoursUntil >= cancelHoursMinimum) return (true, null);
    return (false, cancelHoursMinimum);
  }

  /// Cancels the current appointment. Fails if outside brand's cancel window.
  Future<bool> cancel() async {
    final d = data;
    if (d == null) return false;
    if (!d.canCancel) {
      setError(
        d.cancelHoursRequired != null
            ? 'Cancellation must be done at least ${d.cancelHoursRequired} hours before the appointment'
            : 'Cancellation not allowed',
        null,
      );
      return false;
    }

    // Do not call setLoading() - it would unmount the page body and prevent
    // the success callback from running. The UI shows button spinner via _isCancelling.
    final brandResult = await _brandRepository.getById(d.appointment.brandId);
    final cancelHours = brandResult.fold(
      (_) => 0,
      (b) => b?.cancelHoursMinimum ?? 0,
    );
    final result = await _bookingTransaction.cancelAppointment(
      d.appointment,
      cancelHoursMinimum: cancelHours,
    );
    return result.fold(
      (f) {
        setError(f.message, f);
        return false;
      },
      (_) {
        setData(d);
        return true;
      },
    );
  }
}
