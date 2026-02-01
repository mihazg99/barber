import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';

abstract class UserRepository {
  /// Fetches a user by id (Firebase Auth UID).
  Future<Either<Failure, UserEntity?>> getById(String userId);

  /// Creates or overwrites a user. doc_id = [entity.userId].
  Future<Either<Failure, void>> set(UserEntity entity);
}
