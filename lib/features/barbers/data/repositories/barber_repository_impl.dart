import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
import 'package:barber/features/barbers/data/mappers/barber_firestore_mapper.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/barbers/domain/repositories/barber_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:barber/core/data/services/versioned_cache_service.dart';

class BarberRepositoryImpl implements BarberRepository {
  BarberRepositoryImpl(this._firestore, this._cacheService);

  final FirebaseFirestore _firestore;
  final VersionedCacheService _cacheService;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.barbers);

  // Simple memory cache
  final Map<String, BarberEntity> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  final Map<String, Future<Either<Failure, BarberEntity?>>> _inflight = {};
  static const _ttl = Duration(minutes: 5);

  @override
  Future<Either<Failure, List<BarberEntity>>> getByBrandId(
    String brandId, {
    int? version,
  }) async {
    if (version != null) {
      return _cacheService.fetchVersionedList<BarberEntity>(
        brandId: brandId,
        key: 'barbers',
        remoteVersion: version,
        fromJson:
            (json) => BarberFirestoreMapper.fromMap(
              json,
              json['id'] as String, // Restore ID from JSON
            ),
        toJson: (entity) {
          final map = BarberFirestoreMapper.toFirestore(entity);
          map['id'] = entity.barberId; // Save ID for restoration
          return map;
        },
        onFetch: () async {
          try {
            final snapshot = await FirestoreLogger.logRead(
              '${FirestoreCollections.barbers}?brand_id=$brandId',
              () => _col.where('brand_id', isEqualTo: brandId).get(),
            );
            final list =
                snapshot.docs
                    .map((d) => BarberFirestoreMapper.fromFirestore(d))
                    .toList();
            return Right(list);
          } catch (e) {
            return Left(FirestoreFailure('Failed to get barbers: $e'));
          }
        },
      );
    }

    // Fallback or No Version provided: Fresh Fetch
    try {
      final snapshot = await FirestoreLogger.logRead(
        '${FirestoreCollections.barbers}?brand_id=$brandId',
        () => _col.where('brand_id', isEqualTo: brandId).get(),
      );
      final list =
          snapshot.docs
              .map((d) => BarberFirestoreMapper.fromFirestore(d))
              .toList();
      return Right(list);
    } catch (e) {
      return Left(FirestoreFailure('Failed to get barbers: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BarberEntity>>> getByLocationId(
    String locationId,
  ) async {
    try {
      final snapshot = await FirestoreLogger.logRead(
        '${FirestoreCollections.barbers}?location_ids contains $locationId',
        () => _col.where('location_ids', arrayContains: locationId).get(),
      );
      final list =
          snapshot.docs
              .map((d) => BarberFirestoreMapper.fromFirestore(d))
              .toList();
      return Right(list);
    } catch (e) {
      return Left(FirestoreFailure('Failed to get barbers by location: $e'));
    }
  }

  @override
  Future<Either<Failure, BarberEntity?>> getById(String barberId) async {
    // Check memory cache
    if (_cache.containsKey(barberId) && _cacheTime.containsKey(barberId)) {
      final now = DateTime.now();
      if (now.difference(_cacheTime[barberId]!) < _ttl) {
        return Right(_cache[barberId]);
      }
    }

    // Check in-flight requests
    if (_inflight.containsKey(barberId)) {
      return _inflight[barberId]!;
    }

    final future = () async {
      try {
        final doc = await FirestoreLogger.logRead(
          '${FirestoreCollections.barbers}/$barberId',
          () => _col.doc(barberId).get(),
        );
        if (doc.data() == null)
          return const Right<Failure, BarberEntity?>(null);
        final entity = BarberFirestoreMapper.fromFirestore(doc);

        // Update cache
        _cache[barberId] = entity;
        _cacheTime[barberId] = DateTime.now();

        return Right<Failure, BarberEntity?>(entity);
      } catch (e) {
        return Left<Failure, BarberEntity?>(
          FirestoreFailure('Failed to get barber: $e'),
        );
      } finally {
        _inflight.remove(barberId);
      }
    }();

    _inflight[barberId] = future;
    return future;
  }

  @override
  Future<Either<Failure, BarberEntity?>> getByUserId(String userId) async {
    try {
      final snapshot = await FirestoreLogger.logRead(
        '${FirestoreCollections.barbers}?user_id=$userId',
        () => _col.where('user_id', isEqualTo: userId).limit(1).get(),
      );
      if (snapshot.docs.isEmpty) return const Right(null);
      return Right(BarberFirestoreMapper.fromFirestore(snapshot.docs.first));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get barber by user: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> set(BarberEntity entity) async {
    try {
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.barbers}/${entity.barberId}',
        'set',
        () => _col
            .doc(entity.barberId)
            .set(
              BarberFirestoreMapper.toFirestore(entity),
              SetOptions(merge: true), // Merge to preserve existing fields
            ),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to set barber: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String barberId) async {
    try {
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.barbers}/$barberId',
        'delete',
        () => _col.doc(barberId).delete(),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to delete barber: $e'));
    }
  }
}
