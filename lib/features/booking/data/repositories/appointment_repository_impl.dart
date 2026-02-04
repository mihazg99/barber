import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/features/booking/data/mappers/appointment_firestore_mapper.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/booking/domain/repositories/appointment_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.appointments);

  @override
  Future<Either<Failure, void>> create(AppointmentEntity entity) async {
    try {
      final data = AppointmentFirestoreMapper.toFirestore(entity);
      data['created_at'] = FieldValue.serverTimestamp();
      await _col.doc(entity.appointmentId).set(data);
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to create appointment: $e'));
    }
  }

  /// Never use cache: appointments must reflect server state so all devices see the same data.
  static const _serverOnly = GetOptions(source: Source.server);

  @override
  Future<Either<Failure, AppointmentEntity?>> getById(String appointmentId) async {
    try {
      final doc = await _col.doc(appointmentId).get(_serverOnly);
      if (doc.data() == null) return const Right(null);
      return Right(AppointmentFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get appointment: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getByUserId(
    String userId,
  ) async {
    try {
      final snapshot =
          await _col.where('user_id', isEqualTo: userId).get(_serverOnly);
      final list = snapshot.docs
          .map((d) => AppointmentFirestoreMapper.fromFirestore(d))
          .toList();
      return Right(list);
    } catch (e) {
      return Left(FirestoreFailure('Failed to get appointments by user: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      await _col.doc(appointmentId).update({'status': status});
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to update appointment status: $e'));
    }
  }
}
