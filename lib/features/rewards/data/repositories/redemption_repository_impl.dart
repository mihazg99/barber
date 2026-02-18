import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
import 'package:barber/features/rewards/data/mappers/redemption_firestore_mapper.dart';
import 'package:barber/features/rewards/domain/entities/redemption_entity.dart';
import 'package:barber/features/rewards/domain/repositories/redemption_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:barber/core/data/services/versioned_cache_service.dart';

class RedemptionRepositoryImpl implements RedemptionRepository {
  RedemptionRepositoryImpl(this._firestore, this._cacheService);

  final FirebaseFirestore _firestore;
  final VersionedCacheService _cacheService;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.rewardRedemptions);

  @override
  Future<Either<Failure, List<RedemptionEntity>>> getByUserId(
    String userId, {
    int? version,
  }) async {
    List<RedemptionEntity> list;
    if (version != null) {
      final result = await _cacheService.fetchVersionedList<RedemptionEntity>(
        brandId: 'user_$userId', // Unique key for user redemptions
        key: 'reward_redemptions',
        remoteVersion: version,
        fromJson:
            (json) => RedemptionFirestoreMapper.fromMap(
              json,
              json['id'] as String, // Restore ID
            ),
        toJson: (entity) {
          final map = RedemptionFirestoreMapper.toFirestore(entity);
          map['id'] = entity.redemptionId; // Save ID
          return map;
        },
        onFetch: () async {
          try {
            final snapshot = await FirestoreLogger.logRead(
              '${FirestoreCollections.rewardRedemptions}?user_id=$userId',
              () => _col.where('user_id', isEqualTo: userId).get(),
            );
            final fetched =
                snapshot.docs
                    .map((d) => RedemptionFirestoreMapper.fromFirestore(d))
                    .toList();
            return Right(fetched);
          } catch (e) {
            return Left(FirestoreFailure('Failed to get redemptions: $e'));
          }
        },
      );
      if (result.isLeft()) return result;
      list = result.getOrElse(() => []);
    } else {
      // Fallback
      try {
        final snapshot = await FirestoreLogger.logRead(
          '${FirestoreCollections.rewardRedemptions}?user_id=$userId',
          () => _col.where('user_id', isEqualTo: userId).get(),
        );
        list =
            snapshot.docs
                .map((d) => RedemptionFirestoreMapper.fromFirestore(d))
                .toList();
      } catch (e) {
        return Left(FirestoreFailure('Failed to get redemptions: $e'));
      }
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Right(list);
  }

  @override
  Future<Either<Failure, RedemptionEntity?>> getById(
    String redemptionId,
  ) async {
    try {
      final doc = await FirestoreLogger.logRead(
        '${FirestoreCollections.rewardRedemptions}/$redemptionId',
        () => _col.doc(redemptionId).get(),
      );
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
      final doc = await FirestoreLogger.logRead(
        '${FirestoreCollections.rewardRedemptions}/$redemptionId',
        () => _col.doc(redemptionId).get(),
      );
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
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.rewardRedemptions}/$redemptionId',
        'update',
        () => _col.doc(redemptionId).update({
          'status': RedemptionStatus.redeemed.value,
          'redeemed_at': FieldValue.serverTimestamp(),
          'redeemed_by': redeemedByUserId,
        }),
      );
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
