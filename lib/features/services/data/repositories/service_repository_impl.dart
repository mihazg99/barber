import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
import 'package:barber/features/services/data/mappers/service_firestore_mapper.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:barber/features/services/domain/repositories/service_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  ServiceRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.services);

  @override
  Future<Either<Failure, List<ServiceEntity>>> getByBrandId(String brandId) async {
    try {
      final snapshot = await FirestoreLogger.logRead(
        '${FirestoreCollections.services}?brand_id=$brandId',
        () => _col.where('brand_id', isEqualTo: brandId).get(),
      );
      final list = snapshot.docs
          .map((d) => ServiceFirestoreMapper.fromFirestore(d))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(FirestoreFailure('Failed to get services: $e'));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity?>> getById(String serviceId) async {
    try {
      final doc = await FirestoreLogger.logRead(
        '${FirestoreCollections.services}/$serviceId',
        () => _col.doc(serviceId).get(),
      );
      if (doc.data() == null) return const Right(null);
      return Right(ServiceFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get service: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> set(ServiceEntity entity) async {
    try {
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.services}/${entity.serviceId}',
        'set',
        () => _col.doc(entity.serviceId).set(
              ServiceFirestoreMapper.toFirestore(entity),
            ),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to set service: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String serviceId) async {
    try {
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.services}/$serviceId',
        'delete',
        () => _col.doc(serviceId).delete(),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to delete service: $e'));
    }
  }
}
