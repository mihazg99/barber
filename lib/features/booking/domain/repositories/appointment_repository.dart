import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';

abstract class AppointmentRepository {
  /// Creates an appointment. Sets [created_at] via server timestamp. doc_id = [entity.appointmentId].
  Future<Either<Failure, void>> create(AppointmentEntity entity);

  /// Fetches an appointment by id.
  Future<Either<Failure, AppointmentEntity?>> getById(String appointmentId);

  /// Fetches all appointments for a user.
  Future<Either<Failure, List<AppointmentEntity>>> getByUserId(String userId);

  /// Fetches the user's active scheduled appointment (from user_booking_locks). Used when barber scans loyalty QR.
  Future<Either<Failure, AppointmentEntity?>>
  getActiveScheduledAppointmentForUser(
    String userId,
  );

  /// Clears user_booking_locks active_appointment_id when barber marks visit complete. Idempotent if lock doesn't match.
  Future<Either<Failure, void>> clearActiveAppointmentLock(
    String userId,
    String appointmentId,
  );

  /// Stream of the user's active appointment id (from user_booking_locks). Emits null when lock is cleared.
  Stream<String?> watchActiveAppointmentId(String userId);

  /// Stream of an appointment by id. When status changes to completed, consumer can treat as no longer upcoming.
  Stream<AppointmentEntity?> watchAppointment(String appointmentId);

  /// Stream of upcoming scheduled appointments for a barber (start_time >= start of today).
  /// Sorted by start_time ascending.
  Stream<List<AppointmentEntity>> watchUpcomingAppointmentsForBarber(
    String barberId,
  );

  /// Stream of upcoming scheduled appointments for a user (start_time >= now).
  /// Sorted by start_time ascending.
  Stream<List<AppointmentEntity>> watchUpcomingAppointmentsForUser(
    String userId,
  );

  /// Updates appointment status.
  Future<Either<Failure, void>> updateStatus(
    String appointmentId,
    String status,
  );
}
