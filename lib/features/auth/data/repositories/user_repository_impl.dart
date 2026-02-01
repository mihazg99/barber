import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
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
      final doc = await _col.doc(userId).get();
      if (doc.data() == null) return const Right(null);
      return Right(UserFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get user: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> set(UserEntity entity) async {
    try {
      await _col.doc(entity.userId).set(UserFirestoreMapper.toFirestore(entity));
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to set user: $e'));
    }
  }
}
