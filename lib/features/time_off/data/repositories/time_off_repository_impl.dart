import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
import 'package:barber/features/time_off/data/mappers/time_off_firestore_mapper.dart';
import 'package:barber/features/time_off/domain/entities/time_off_entity.dart';
import 'package:barber/features/time_off/domain/repositories/time_off_repository.dart';

class TimeOffRepositoryImpl implements TimeOffRepository {
  TimeOffRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.timeOff);

  // Simple memory cache
  final Map<String, List<TimeOffEntity>> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  final Map<String, Future<Either<Failure, List<TimeOffEntity>>>> _inflight =
      {};
  static const _ttl = Duration(minutes: 5);

  static const _serverOnly = GetOptions(source: Source.server);

  @override
  Future<Either<Failure, void>> create(TimeOffEntity entity) async {
    try {
      final data = TimeOffFirestoreMapper.toFirestore(entity);
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.timeOff}/${entity.timeOffId}',
        'set',
        () => _col.doc(entity.timeOffId).set(data),
      );
      // Invalidate cache for this barber
      _cache.remove(entity.barberId);
      _cacheTime.remove(entity.barberId);
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to create time-off: $e'));
    }
  }

  @override
  Future<Either<Failure, TimeOffEntity?>> getById(String timeOffId) async {
    try {
      final doc = await FirestoreLogger.logRead(
        '${FirestoreCollections.timeOff}/$timeOffId',
        () => _col.doc(timeOffId).get(_serverOnly),
      );
      if (doc.data() == null) return const Right(null);
      return Right(TimeOffFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get time-off: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TimeOffEntity>>> getByBarberId(
    String barberId,
  ) async {
    // Check memory cache
    if (_cache.containsKey(barberId) && _cacheTime.containsKey(barberId)) {
      final now = DateTime.now();
      if (now.difference(_cacheTime[barberId]!) < _ttl) {
        return Right(_cache[barberId]!);
      }
    }

    // Check in-flight requests
    if (_inflight.containsKey(barberId)) {
      return _inflight[barberId]!;
    }

    final future = () async {
      try {
        final snapshot = await FirestoreLogger.logRead(
          '${FirestoreCollections.timeOff}?barber_id=$barberId',
          () => _col
              .where('barber_id', isEqualTo: barberId)
              .orderBy('start_date', descending: false)
              .get(_serverOnly),
        );
        final list =
            snapshot.docs
                .map((d) => TimeOffFirestoreMapper.fromFirestore(d))
                .toList();

        // Update cache
        _cache[barberId] = list;
        _cacheTime[barberId] = DateTime.now();

        return Right<Failure, List<TimeOffEntity>>(list);
      } catch (e) {
        return Left<Failure, List<TimeOffEntity>>(
          FirestoreFailure('Failed to get time-off by barber: $e'),
        );
      } finally {
        _inflight.remove(barberId);
      }
    }();

    _inflight[barberId] = future;
    return future;
  }

  @override
  Future<Either<Failure, List<TimeOffEntity>>> getByBarberIdAndDate(
    String barberId,
    DateTime date,
  ) async {
    try {
      // Get all time-off for barber and filter client-side
      // This avoids complex Firestore queries with date ranges
      final result = await getByBarberId(barberId);
      return result.fold(
        Left.new,
        (timeOffList) {
          final filtered =
              timeOffList.where((timeOff) => timeOff.coversDate(date)).toList();
          return Right(filtered);
        },
      );
    } catch (e) {
      return Left(
        FirestoreFailure('Failed to get time-off by barber and date: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> update(TimeOffEntity entity) async {
    try {
      final data = TimeOffFirestoreMapper.toFirestore(entity);
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.timeOff}/${entity.timeOffId}',
        'update',
        () => _col.doc(entity.timeOffId).update(data),
      );
      // Invalidate cache for this barber
      _cache.remove(entity.barberId);
      _cacheTime.remove(entity.barberId);
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to update time-off: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String timeOffId) async {
    try {
      // We need to get the entity first to know which barber cache to invalidate
      // Or we could just clear all caches, but getting it is safer if possible.
      // Since delete usually happens from UI where we might have the entity,
      // but here we only have ID.
      // For now, let's just do the delete. Ideally we'd know the barberId.
      // OPTIMIZATION: Try to fetch it first from cache if possible, or just accept
      // that we might need to rely on TTL or manual refresh elsewhere.
      // BUT, to be safe, let's try to find it in our memory cache to invalidate.

      String? barberIdToInvalidate;
      for (final entry in _cache.entries) {
        if (entry.value.any((e) => e.timeOffId == timeOffId)) {
          barberIdToInvalidate = entry.key;
          break;
        }
      }

      await FirestoreLogger.logWrite(
        '${FirestoreCollections.timeOff}/$timeOffId',
        'delete',
        () => _col.doc(timeOffId).delete(),
      );

      if (barberIdToInvalidate != null) {
        _cache.remove(barberIdToInvalidate);
        _cacheTime.remove(barberIdToInvalidate);
      } else {
        // Fallback: clear all or do nothing?
        // If it's not in cache, we don't need to invalidate.
      }

      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to delete time-off: $e'));
    }
  }

  @override
  Stream<List<TimeOffEntity>> watchByBarberId(String barberId) {
    return FirestoreLogger.logStream<List<TimeOffEntity>>(
      '${FirestoreCollections.timeOff}?barber_id=$barberId',
      _col
          .where('barber_id', isEqualTo: barberId)
          .orderBy('start_date', descending: false)
          .snapshots()
          .map(
            (snap) =>
                snap.docs
                    .map((d) => TimeOffFirestoreMapper.fromFirestore(d))
                    .toList(),
          ),
    );
  }
}
