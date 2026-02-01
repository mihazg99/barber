import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/features/locations/data/mappers/location_firestore_mapper.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/locations/domain/repositories/location_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.locations);

  @override
  Future<Either<Failure, List<LocationEntity>>> getByBrandId(String brandId) async {
    try {
      final snapshot = await _col.where('brand_id', isEqualTo: brandId).get();
      final list = snapshot.docs
          .map((d) => LocationFirestoreMapper.fromFirestore(d))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(FirestoreFailure('Failed to get locations: $e'));
    }
  }

  @override
  Future<Either<Failure, LocationEntity?>> getById(String locationId) async {
    try {
      final doc = await _col.doc(locationId).get();
      if (doc.data() == null) return const Right(null);
      return Right(LocationFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get location: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> set(LocationEntity entity) async {
    try {
      await _col.doc(entity.locationId).set(
            LocationFirestoreMapper.toFirestore(entity),
          );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to set location: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String locationId) async {
    try {
      await _col.doc(locationId).delete();
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to delete location: $e'));
    }
  }
}
