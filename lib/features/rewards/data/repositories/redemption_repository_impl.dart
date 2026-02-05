import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/features/rewards/data/mappers/redemption_firestore_mapper.dart';
import 'package:barber/features/rewards/domain/entities/redemption_entity.dart';
import 'package:barber/features/rewards/domain/repositories/redemption_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RedemptionRepositoryImpl implements RedemptionRepository {
  RedemptionRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.rewardRedemptions);

  @override
  Future<Either<Failure, List<RedemptionEntity>>> getByUserId(
    String userId,
  ) async {
    try {
      final snapshot = await _col.where('user_id', isEqualTo: userId).get();
      final list =
          snapshot.docs
              .map((d) => RedemptionFirestoreMapper.fromFirestore(d))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Right(list);
    } catch (e) {
      return Left(FirestoreFailure('Failed to get redemptions: $e'));
    }
  }

  @override
  Future<Either<Failure, RedemptionEntity?>> getById(
    String redemptionId,
  ) async {
    try {
      final doc = await _col.doc(redemptionId).get();
      if (doc.data() == null) return const Right(null);
      return Right(RedemptionFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get redemption: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markRedeemed({
    required String redemptionId,
    required String redeemedByUserId,
    required String barberBrandId,
  }) async {
    try {
      final doc = await _col.doc(redemptionId).get();
      if (doc.data() == null) {
        return Left(FirestoreFailure('Redemption not found'));
      }
      final r = RedemptionFirestoreMapper.fromFirestore(doc);
      if (r.brandId != barberBrandId) {
        return Left(
          FirestoreFailure(
            'Reward is for another brand',
            code: 'brand-mismatch',
          ),
        );
      }
      if (r.status != RedemptionStatus.pending) {
        return Left(
          FirestoreFailure(
            'Reward already redeemed',
            code: 'already-redeemed',
          ),
        );
      }
      await _col.doc(redemptionId).update({
        'status': RedemptionStatus.redeemed.value,
        'redeemed_at': FieldValue.serverTimestamp(),
        'redeemed_by': redeemedByUserId,
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(
        FirestoreFailure(e.message ?? 'Failed to redeem', code: e.code),
      );
    } catch (e) {
      return Left(FirestoreFailure('Failed to mark redeemed: $e'));
    }
  }
}
