import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';

abstract class BrandRepository {
  /// Fetches a brand by id. Returns [Left] with [FirestoreFailure] if not found or error.
  Future<Either<Failure, BrandEntity?>> getById(String brandId);

  /// Creates or overwrites a brand. doc_id = [entity.brandId].
  Future<Either<Failure, void>> set(BrandEntity entity);

  /// Checks if a tag is available (not taken). Returns true if available.
  Future<Either<Failure, bool>> isTagAvailable(String tag);

  /// Fetches a brand by tag. Returns [null] if not found in Right.
  Future<Either<Failure, BrandEntity?>> getByTag(String tag);
}
