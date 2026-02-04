import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/features/rewards/data/mappers/reward_firestore_mapper.dart';
import 'package:barber/features/rewards/domain/entities/reward_entity.dart';
import 'package:barber/features/rewards/domain/repositories/reward_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardRepositoryImpl implements RewardRepository {
  RewardRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.rewards);

  @override
  Future<Either<Failure, List<RewardEntity>>> getByBrandId(
    String brandId, {
    bool includeInactive = false,
  }) async {
    try {
      final snapshot = await _col.where('brand_id', isEqualTo: brandId).get();
      var list =
          snapshot.docs
              .map((d) => RewardFirestoreMapper.fromFirestore(d))
              .toList();
      if (!includeInactive) {
        list = list.where((r) => r.isActive).toList();
      }
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return Right(list);
    } catch (e) {
      return Left(FirestoreFailure('Failed to get rewards: $e'));
    }
  }

  @override
  Future<Either<Failure, RewardEntity?>> getById(String rewardId) async {
    try {
      final doc = await _col.doc(rewardId).get();
      if (doc.data() == null) return const Right(null);
      return Right(RewardFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get reward: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> set(RewardEntity entity) async {
    try {
      await _col
          .doc(entity.rewardId)
          .set(
            RewardFirestoreMapper.toFirestore(entity),
          );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to set reward: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String rewardId) async {
    try {
      await _col.doc(rewardId).delete();
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to delete reward: $e'));
    }
  }
}
