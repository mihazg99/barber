import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
import 'package:barber/features/auth/data/mappers/user_firestore_mapper.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/auth/domain/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.users);

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
        () => _col.doc(entity.userId).set(UserFirestoreMapper.toFirestore(entity)),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to set user: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addLoyaltyPoints(String userId, int pointsToAdd) async {
    if (pointsToAdd <= 0) return const Right(null);
    try {
      await FirestoreLogger.logTransaction(
        'users/$userId addLoyaltyPoints',
        (transaction) async {
          final ref = _col.doc(userId);
          final snap = await transaction.get(ref);
        final data = snap.data();
        if (data == null) throw Exception('User not found');
        final current = (data['loyalty_points'] as num?)?.toInt() ?? 0;
        transaction.update(ref, {'loyalty_points': current + pointsToAdd});
        },
      _firestore);
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to add loyalty points: $e'));
    }
  }
}
