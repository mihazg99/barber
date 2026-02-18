import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
import 'package:barber/features/locations/data/mappers/location_firestore_mapper.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/locations/domain/repositories/location_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:barber/core/data/services/versioned_cache_service.dart';

class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._firestore, this._cacheService);

  final FirebaseFirestore _firestore;
  final VersionedCacheService _cacheService;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.locations);

  @override
  Future<Either<Failure, List<LocationEntity>>> getByBrandId(
    String brandId, {
    int? version,
  }) async {
    if (version != null) {
      return _cacheService.fetchVersionedList<LocationEntity>(
        brandId: brandId,
        key: 'locations',
        remoteVersion: version,
        fromJson:
            (json) => LocationFirestoreMapper.fromMap(
              json,
              json['id'] as String, // Restore ID
            ),
        toJson: (entity) {
          final map = LocationFirestoreMapper.toFirestore(entity);
          map['id'] = entity.locationId; // Save ID
          if (map['geo_point'] is GeoPoint) {
            final geo = map['geo_point'] as GeoPoint;
            map['geo_point'] = {'lat': geo.latitude, 'lng': geo.longitude};
          }
          return map;
        },
        onFetch: () async {
          try {
            final snapshot = await FirestoreLogger.logRead(
              '${FirestoreCollections.locations}?brand_id=$brandId',
              () => _col.where('brand_id', isEqualTo: brandId).get(),
            );
            final list =
                snapshot.docs
                    .map((d) => LocationFirestoreMapper.fromFirestore(d))
                    .toList();
            return Right(list);
          } catch (e) {
            return Left(FirestoreFailure('Failed to get locations: $e'));
          }
        },
      );
    }

    // Fallback
    try {
      final snapshot = await FirestoreLogger.logRead(
        '${FirestoreCollections.locations}?brand_id=$brandId',
        () => _col.where('brand_id', isEqualTo: brandId).get(),
      );
      final list =
          snapshot.docs
              .map((d) => LocationFirestoreMapper.fromFirestore(d))
              .toList();
      return Right(list);
    } catch (e) {
      return Left(FirestoreFailure('Failed to get locations: $e'));
    }
  }

  @override
  Future<Either<Failure, LocationEntity?>> getById(String locationId) async {
    if (locationId.isEmpty) return const Right(null);
    try {
      final doc = await FirestoreLogger.logRead(
        '${FirestoreCollections.locations}/$locationId',
        () => _col.doc(locationId).get(),
      );
      if (doc.data() == null) return const Right(null);
      return Right(LocationFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get location: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> set(LocationEntity entity) async {
    try {
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.locations}/${entity.locationId}',
        'set',
        () => _col
            .doc(entity.locationId)
            .set(
              LocationFirestoreMapper.toFirestore(entity),
            ),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to set location: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String locationId) async {
    try {
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.locations}/$locationId',
        'delete',
        () => _col.doc(locationId).delete(),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to delete location: $e'));
    }
  }
}
