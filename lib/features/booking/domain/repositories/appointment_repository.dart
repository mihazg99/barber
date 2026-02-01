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

  /// Updates appointment status.
  Future<Either<Failure, void>> updateStatus(String appointmentId, String status);
}
