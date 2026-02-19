import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
import 'package:barber/features/brand/data/mappers/brand_firestore_mapper.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrandRepositoryImpl implements BrandRepository {
  BrandRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.brands);

  // Simple memory cache
  final Map<String, BrandEntity> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  final Map<String, Future<Either<Failure, BrandEntity?>>> _inflight = {};
  static const _ttl = Duration(minutes: 5);

  @override
  Future<Either<Failure, BrandEntity?>> getById(String brandId) async {
    // Check memory cache
    if (_cache.containsKey(brandId) && _cacheTime.containsKey(brandId)) {
      final now = DateTime.now();
      if (now.difference(_cacheTime[brandId]!) < _ttl) {
        return Right(_cache[brandId]);
      }
    }

    // Check in-flight requests
    if (_inflight.containsKey(brandId)) {
      return _inflight[brandId]!;
    }

    final future = () async {
      try {
        final doc = await FirestoreLogger.logRead(
          '${FirestoreCollections.brands}/$brandId',
          () => _col.doc(brandId).get(),
        );
        if (doc.data() == null) return const Right<Failure, BrandEntity?>(null);
        final entity = BrandFirestoreMapper.fromFirestore(doc);

        // Update cache
        _cache[brandId] = entity;
        _cacheTime[brandId] = DateTime.now();

        return Right<Failure, BrandEntity?>(entity);
      } catch (e) {
        return Left<Failure, BrandEntity?>(
          FirestoreFailure('Failed to get brand: $e'),
        );
      } finally {
        _inflight.remove(brandId);
      }
    }();

    _inflight[brandId] = future;
    return future;
  }

  @override
  Future<Either<Failure, void>> set(BrandEntity entity) async {
    try {
      // Update cache immediately (Optimistic UI)
      _cache[entity.brandId] = entity;
      _cacheTime[entity.brandId] = DateTime.now();

      await FirestoreLogger.logWrite(
        '${FirestoreCollections.brands}/${entity.brandId}',
        'set',
        () => _col
            .doc(entity.brandId)
            .set(BrandFirestoreMapper.toFirestore(entity)),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to set brand: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isTagAvailable(String tag) async {
    try {
      final snapshot = await FirestoreLogger.logRead(
        '${FirestoreCollections.brands}?tag=$tag',
        () => _col.where('tag', isEqualTo: tag).limit(1).get(),
      );
      return Right(snapshot.docs.isEmpty);
    } catch (e) {
      return Left(FirestoreFailure('Failed to check tag availability: $e'));
    }
  }

  @override
  Future<Either<Failure, BrandEntity?>> getByTag(String tag) async {
    try {
      final snapshot = await FirestoreLogger.logRead(
        '${FirestoreCollections.brands}?tag=$tag',
        () => _col.where('tag', isEqualTo: tag).limit(1).get(),
      );
      if (snapshot.docs.isEmpty) return const Right(null);
      return Right(BrandFirestoreMapper.fromFirestore(snapshot.docs.first));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get brand by tag: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateServiceCategories(
    String brandId,
    List<String> categories,
  ) async {
    try {
      // Update cache if exists
      if (_cache.containsKey(brandId)) {
        final current = _cache[brandId]!;
        _cache[brandId] = current.copyWith(serviceCategories: categories);
        _cacheTime[brandId] = DateTime.now();
      }

      await FirestoreLogger.logWrite(
        '${FirestoreCollections.brands}/$brandId',
        'updateServiceCategories',
        () => _col.doc(brandId).update({'service_categories': categories}),
      );
      return const Right(null);
    } catch (e) {
      return Left(
        FirestoreFailure('Failed to update service categories: $e'),
      );
    }
  }
}
