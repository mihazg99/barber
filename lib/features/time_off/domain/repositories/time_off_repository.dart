import 'package:dartz/dartz.dart';

import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/time_off/domain/entities/time_off_entity.dart';

/// Repository for time-off CRUD operations.
abstract class TimeOffRepository {
  /// Create a new time-off period.
  Future<Either<Failure, void>> create(TimeOffEntity entity);

  /// Get time-off by ID.
  Future<Either<Failure, TimeOffEntity?>> getById(String timeOffId);

  /// Get all time-off periods for a barber.
  Future<Either<Failure, List<TimeOffEntity>>> getByBarberId(String barberId);

  /// Get time-off periods for a barber that cover a specific date.
  Future<Either<Failure, List<TimeOffEntity>>> getByBarberIdAndDate(
    String barberId,
    DateTime date,
  );

  /// Update an existing time-off period.
  Future<Either<Failure, void>> update(TimeOffEntity entity);

  /// Delete a time-off period.
  Future<Either<Failure, void>> delete(String timeOffId);

  /// Stream of time-off periods for a barber.
  Stream<List<TimeOffEntity>> watchByBarberId(String barberId);
}
