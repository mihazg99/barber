import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/booking/domain/entities/availability_entity.dart';

abstract class AvailabilityRepository {
  /// Fetches availability by doc id (barber_id_YYYY-MM-DD).
  Future<Either<Failure, AvailabilityEntity?>> get(String docId);

  /// Creates or overwrites availability. doc_id = [entity.docId].
  Future<Either<Failure, void>> set(AvailabilityEntity entity);
}
