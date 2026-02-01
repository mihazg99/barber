import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';

abstract class BrandRepository {
  /// Fetches a brand by id. Returns [Left] with [FirestoreFailure] if not found or error.
  Future<Either<Failure, BrandEntity?>> getById(String brandId);

  /// Creates or overwrites a brand. doc_id = [entity.brandId].
  Future<Either<Failure, void>> set(BrandEntity entity);
}
