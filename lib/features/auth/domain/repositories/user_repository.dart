import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';

abstract class UserRepository {
  /// Fetches a user by id (Firebase Auth UID).
  Future<Either<Failure, UserEntity?>> getById(String userId);

  /// Stream of user document so loyalty points update in real time when barber awards points.
  Stream<UserEntity?> watchById(String userId);

  /// Creates or overwrites a user. doc_id = [entity.userId].
  Future<Either<Failure, void>> set(UserEntity entity);

  /// Adds [pointsToAdd] to the user's loyalty_points. Used by barber when scanning loyalty QR.
  Future<Either<Failure, void>> addLoyaltyPoints(String userId, int pointsToAdd);
}
