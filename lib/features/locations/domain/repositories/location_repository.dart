import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

abstract class LocationRepository {
  /// Fetches all locations for a brand.
  Future<Either<Failure, List<LocationEntity>>> getByBrandId(String brandId);

  /// Fetches a location by id.
  Future<Either<Failure, LocationEntity?>> getById(String locationId);

  /// Creates or overwrites a location. doc_id = [entity.locationId].
  Future<Either<Failure, void>> set(LocationEntity entity);

  /// Deletes a location by id.
  Future<Either<Failure, void>> delete(String locationId);
}
