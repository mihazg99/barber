import 'package:dartz/dartz.dart';

import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/brand_selection/data/datasources/user_brands_remote_data_source.dart';
import 'package:barber/features/brand_selection/domain/entities/user_brand_entity.dart';
import 'package:barber/features/brand_selection/domain/failures/brand_selection_failure.dart';
import 'package:barber/features/brand_selection/domain/repositories/user_brands_repository.dart';

class UserBrandsRepositoryImpl implements UserBrandsRepository {
  UserBrandsRepositoryImpl(this._remoteDataSource);

  final UserBrandsRemoteDataSource _remoteDataSource;

  @override
  Stream<Either<Failure, List<UserBrandEntity>>> watchUserBrands(
    String userId,
  ) {
    try {
      return _remoteDataSource
          .watchUserBrands(userId)
          .map(
            (brands) => Right(brands.cast<UserBrandEntity>()),
          );
    } catch (e) {
      return Stream.value(
        Left(BrandSelectionFailure(e.toString())),
      );
    }
  }

  @override
  Future<Either<Failure, UserBrandEntity?>> getUserBrand(
    String userId,
    String brandId,
  ) async {
    try {
      final userBrand = await _remoteDataSource.getUserBrand(userId, brandId);
      return Right(userBrand);
    } catch (e) {
      return Left(BrandSelectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> joinBrand(
    String userId,
    String brandId,
  ) async {
    try {
      // Check if already joined
      final existing = await _remoteDataSource.getUserBrand(userId, brandId);
      if (existing != null) {
        return const Left(BrandAlreadyJoinedFailure());
      }

      await _remoteDataSource.createUserBrand(userId, brandId);
      return const Right(null);
    } catch (e) {
      return Left(BrandSelectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLoyaltyPoints(
    String userId,
    String brandId,
    int points,
  ) async {
    try {
      await _remoteDataSource.updateLoyaltyPoints(userId, brandId, points);
      return const Right(null);
    } catch (e) {
      return Left(BrandSelectionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateLastActive(
    String userId,
    String brandId,
  ) async {
    try {
      await _remoteDataSource.updateLastActive(userId, brandId);
      return const Right(null);
    } catch (e) {
      return Left(BrandSelectionFailure(e.toString()));
    }
  }
}
