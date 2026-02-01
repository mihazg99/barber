import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';

abstract class BarberRepository {
  /// Fetches all barbers for a brand.
  Future<Either<Failure, List<BarberEntity>>> getByBrandId(String brandId);

  /// Fetches all barbers at a location.
  Future<Either<Failure, List<BarberEntity>>> getByLocationId(String locationId);

  /// Fetches a barber by id.
  Future<Either<Failure, BarberEntity?>> getById(String barberId);

  /// Creates or overwrites a barber. doc_id = [entity.barberId].
  Future<Either<Failure, void>> set(BarberEntity entity);

  /// Deletes a barber by id.
  Future<Either<Failure, void>> delete(String barberId);
}
