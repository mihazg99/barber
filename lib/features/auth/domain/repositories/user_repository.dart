import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';

abstract class UserRepository {
  /// Fetches a user by id (Firebase Auth UID).
  /// Merges a new user entity with an existing one (if present) atomically.
  ///
  /// Used during login to ensure we don't overwrite existing data (like role,
  /// brandId, phone) with default values if the user already exists.
  Future<Either<Failure, UserEntity>> mergeOnLogin(UserEntity newUser);

  Future<Either<Failure, UserEntity?>> getById(String userId);

  /// Stream of user document so loyalty points update in real time when barber awards points.
  Stream<UserEntity?> watchById(String userId);

  /// Creates or overwrites a user. doc_id = [entity.userId].
  Future<Either<Failure, void>> set(UserEntity entity);

  /// Adds [pointsToAdd] to the user's loyalty_points. Used by barber when scanning loyalty QR.
  Future<Either<Failure, void>> addLoyaltyPoints(
    String userId,
    int pointsToAdd,
  );

  /// Updates the FCM token for the user (for push notifications). Called when token is obtained or refreshed.
  Future<Either<Failure, void>> updateFcmToken(String userId, String token);
}
