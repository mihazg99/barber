import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
import 'package:barber/features/auth/data/mappers/user_firestore_mapper.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/auth/domain/entities/user_role.dart';
import 'package:barber/features/auth/domain/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.users);

  @override
  Future<Either<Failure, UserEntity>> mergeOnLogin(UserEntity newUser) async {
    try {
      final result = await _firestore.runTransaction((transaction) async {
        final docRef = _col.doc(newUser.userId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists || snapshot.data() == null) {
          // New user: create with provided data
          transaction.set(docRef, UserFirestoreMapper.toFirestore(newUser));
          return newUser;
        }

        // Existing user: merge responsibly
        final existing = UserFirestoreMapper.fromFirestore(snapshot);

        // Logic to determine which fields to keep vs update
        final merged = existing.copyWith(
          // Keep existing name if present, otherwise use new (e.g. from Google/Apple)
          fullName:
              existing.fullName.isNotEmpty
                  ? existing.fullName
                  : newUser.fullName,

          // Keep existing phone if present, otherwise use new
          phone: existing.phone.isNotEmpty ? existing.phone : newUser.phone,

          // Role: Upgrade to superadmin if intent is superadmin, otherwise keep existing.
          // NEVER downgrade a superadmin/barber to user via login.
          role:
              newUser.role == UserRole.superadmin
                  ? UserRole.superadmin
                  : existing.role,

          // Always keep existing IDs/Settings unless specific logic dictates otherwise
          barberId: existing.barberId,
          brandId: existing.brandId,
          preferredBarberId: existing.preferredBarberId,

          // Update FCM token if new one is provided (usually empty on login initial step though)
          fcmToken:
              newUser.fcmToken.isNotEmpty
                  ? newUser.fcmToken
                  : existing.fcmToken,
        );

        transaction.update(docRef, UserFirestoreMapper.toFirestore(merged));
        return merged;
      });

      return Right(result);
    } catch (e) {
      return Left(FirestoreFailure('Failed to merge user on login: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getById(String userId) async {
    try {
      final doc = await FirestoreLogger.logRead(
        '${FirestoreCollections.users}/$userId',
        () => _col.doc(userId).get(),
      );
      if (doc.data() == null) return const Right(null);
      return Right(UserFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get user: $e'));
    }
  }

  @override
  Stream<UserEntity?> watchById(String userId) {
    return FirestoreLogger.logStream<UserEntity?>(
      '${FirestoreCollections.users}/$userId',
      _col.doc(userId).snapshots().map((doc) {
        if (doc.data() == null) return null;
        return UserFirestoreMapper.fromFirestore(doc);
      }),
    );
  }

  @override
  Future<Either<Failure, void>> set(UserEntity entity) async {
    try {
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.users}/${entity.userId}',
        'set',
        () => _col
            .doc(entity.userId)
            .set(
              UserFirestoreMapper.toFirestore(entity),
              SetOptions(merge: true),
            ),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to set user: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addLoyaltyPoints(
    String userId,
    int pointsToAdd,
  ) async {
    if (pointsToAdd <= 0) return const Right(null);
    try {
      await FirestoreLogger.logTransaction('users/$userId addLoyaltyPoints', (
        transaction,
      ) async {
        final ref = _col.doc(userId);
        final snap = await transaction.get(ref);
        final data = snap.data();
        if (data == null) throw Exception('User not found');
        final current = (data['loyalty_points'] as num?)?.toInt() ?? 0;
        transaction.update(ref, {'loyalty_points': current + pointsToAdd});
      }, _firestore);
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to add loyalty points: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateFcmToken(
    String userId,
    String token,
  ) async {
    try {
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.users}/$userId',
        'updateFcmToken',
        () => _col.doc(userId).set(
          {'fcm_token': token},
          SetOptions(merge: true),
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to update FCM token: $e'));
    }
  }
}
