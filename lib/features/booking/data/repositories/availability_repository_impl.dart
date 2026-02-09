import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
import 'package:barber/features/booking/data/mappers/availability_firestore_mapper.dart';
import 'package:barber/features/booking/domain/entities/availability_entity.dart';
import 'package:barber/features/booking/domain/repositories/availability_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailabilityRepositoryImpl implements AvailabilityRepository {
  AvailabilityRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.availability);

  /// Never use cache: availability must reflect server state to prevent double-booking.
  static const _serverOnly = GetOptions(source: Source.server);

  @override
  Future<Either<Failure, AvailabilityEntity?>> get(String docId) async {
    try {
      final doc = await FirestoreLogger.logRead(
        '${FirestoreCollections.availability}/$docId',
        () => _col.doc(docId).get(_serverOnly),
      );
      if (doc.data() == null) return const Right(null);
      return Right(AvailabilityFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get availability: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> set(AvailabilityEntity entity) async {
    try {
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.availability}/${entity.docId}',
        'set',
        () => _col.doc(entity.docId).set(
              AvailabilityFirestoreMapper.toFirestore(entity),
            ),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to set availability: $e'));
    }
  }
}
