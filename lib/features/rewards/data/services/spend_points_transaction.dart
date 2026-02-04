import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const _kInsufficientPoints = 'insufficient-points';
const _kBrandMismatch = 'reward-brand-mismatch';

/// Atomically: deduct user points and create a reward redemption (pending).
/// Returns the new redemption id (for QR) or a failure.
class SpendPointsTransaction {
  SpendPointsTransaction(this._firestore);

  final FirebaseFirestore _firestore;

  /// Spends [reward]'s points for [userId]. User doc and reward must exist and match brand; user must have enough points.
  Future<Either<Failure, String>> run({
    required String userId,
    required String rewardId,
    required String rewardName,
    required String brandId,
    required int pointsCost,
  }) async {
    final userRef = _firestore
        .collection(FirestoreCollections.users)
        .doc(userId);
    final redemptionsRef = _firestore.collection(
      FirestoreCollections.rewardRedemptions,
    );
    final redemptionRef = redemptionsRef.doc();

    try {
      await _firestore.runTransaction((Transaction transaction) async {
        final userSnap = await transaction.get(userRef);
        if (!userSnap.exists || userSnap.data() == null) {
          throw FirebaseException(
            plugin: 'rewards',
            code: 'user-not-found',
            message: 'User not found',
          );
        }
        final userData = userSnap.data()!;
        final userBrandId = userData['brand_id'] as String? ?? '';
        final currentPoints =
            (userData['loyalty_points'] as num?)?.toInt() ?? 0;

        if (userBrandId != brandId) {
          throw FirebaseException(
            plugin: 'rewards',
            code: _kBrandMismatch,
            message: 'Reward is for another brand',
          );
        }
        if (currentPoints < pointsCost) {
          throw FirebaseException(
            plugin: 'rewards',
            code: _kInsufficientPoints,
            message: 'Not enough points',
          );
        }

        transaction.set(redemptionRef, {
          'user_id': userId,
          'reward_id': rewardId,
          'brand_id': brandId,
          'reward_name': rewardName,
          'points_spent': pointsCost,
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
        });

        transaction.update(userRef, {
          'loyalty_points': currentPoints - pointsCost,
        });
      });
      return Right(redemptionRef.id);
    } on FirebaseException catch (e) {
      return Left(
        FirestoreFailure(e.message ?? 'Transaction failed', code: e.code),
      );
    } catch (e) {
      return Left(FirestoreFailure('Spend points failed: $e'));
    }
  }
}
