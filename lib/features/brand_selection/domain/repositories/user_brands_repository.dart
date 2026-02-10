import 'package:dartz/dartz.dart';

import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/brand_selection/domain/entities/user_brand_entity.dart';

/// Repository for managing user's brand memberships.
abstract class UserBrandsRepository {
  /// Watch all brands the user has joined.
  Stream<Either<Failure, List<UserBrandEntity>>> watchUserBrands(String userId);

  /// Get a specific user brand.
  Future<Either<Failure, UserBrandEntity?>> getUserBrand(
    String userId,
    String brandId,
  );

  /// Join a brand (create user_brands document).
  Future<Either<Failure, void>> joinBrand(String userId, String brandId);

  /// Update loyalty points for a user's brand.
  Future<Either<Failure, void>> updateLoyaltyPoints(
    String userId,
    String brandId,
    int points,
  );

  /// Update last active timestamp.
  Future<Either<Failure, void>> updateLastActive(
    String userId,
    String brandId,
  );
}
