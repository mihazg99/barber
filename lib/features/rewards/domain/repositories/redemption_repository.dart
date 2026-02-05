import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/rewards/domain/entities/redemption_entity.dart';

abstract class RedemptionRepository {
  /// Lists redemptions for a user (for "my rewards" and QR display).
  Future<Either<Failure, List<RedemptionEntity>>> getByUserId(String userId);

  /// Fetches a single redemption by id (for barber scan lookup).
  Future<Either<Failure, RedemptionEntity?>> getById(String redemptionId);

  /// Barber marks redemption as fulfilled. Fails if already redeemed or brand mismatch.
  Future<Either<Failure, void>> markRedeemed({
    required String redemptionId,
    required String redeemedByUserId,
    required String barberBrandId,
  });
}
