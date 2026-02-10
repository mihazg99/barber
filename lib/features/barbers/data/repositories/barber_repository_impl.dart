import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
import 'package:barber/features/barbers/data/mappers/barber_firestore_mapper.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/barbers/domain/repositories/barber_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BarberRepositoryImpl implements BarberRepository {
  BarberRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.barbers);

  @override
  Future<Either<Failure, List<BarberEntity>>> getByBrandId(
    String brandId,
  ) async {
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
    try {
      final doc = await FirestoreLogger.logRead(
        '${FirestoreCollections.barbers}/$barberId',
        () => _col.doc(barberId).get(),
      );
      if (doc.data() == null) return const Right(null);
      return Right(BarberFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get barber: $e'));
    }
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
