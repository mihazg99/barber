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

  /// Never use cache: appointments must reflect server state so all devices see the same data.
  static const _serverOnly = GetOptions(source: Source.server);

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

  @override
  Future<Either<Failure, AppointmentEntity?>> getById(
    String appointmentId,
  ) async {
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
      final list =
          snapshot.docs
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

  @override
  Future<Either<Failure, AppointmentEntity?>> getActiveScheduledAppointmentForUser(
    String userId,
  ) async {
    try {
      final lockRef = _firestore
          .collection(FirestoreCollections.userBookingLocks)
          .doc(userId);
      final lockSnap = await lockRef.get(_serverOnly);
      final activeId = lockSnap.data()?['active_appointment_id'] as String?;
      if (activeId == null || activeId.isEmpty) return const Right(null);
      final apptResult = await getById(activeId);
      return apptResult.fold(
        Left.new,
        (appt) => Right(
          appt != null && appt.status == AppointmentStatus.scheduled
              ? appt
              : null,
        ),
      );
    } catch (e) {
      return Left(FirestoreFailure(
        'Failed to get active appointment for user: $e',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> clearActiveAppointmentLock(
    String userId,
    String appointmentId,
  ) async {
    try {
      final lockRef = _firestore
          .collection(FirestoreCollections.userBookingLocks)
          .doc(userId);
      final lockSnap = await lockRef.get(_serverOnly);
      final currentId = lockSnap.data()?['active_appointment_id'] as String?;
      if (currentId == appointmentId) {
        await lockRef.update({'active_appointment_id': FieldValue.delete()});
      }
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure(
        'Failed to clear active appointment lock: $e',
      ));
    }
  }

  @override
  Stream<String?> watchActiveAppointmentId(String userId) {
    final lockRef = _firestore
        .collection(FirestoreCollections.userBookingLocks)
        .doc(userId);
    return lockRef.snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      final id = data['active_appointment_id'] as String?;
      return (id != null && id.isNotEmpty) ? id : null;
    });
  }

  @override
  Stream<AppointmentEntity?> watchAppointment(String appointmentId) {
    return _col.doc(appointmentId).snapshots().map((doc) {
      if (doc.data() == null) return null;
      return AppointmentFirestoreMapper.fromFirestore(doc);
    });
  }

  @override
  Stream<List<AppointmentEntity>> watchUpcomingAppointmentsForBarber(
    String barberId,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return _col
        .where('barber_id', isEqualTo: barberId)
        .where('status', isEqualTo: AppointmentStatus.scheduled)
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .orderBy('start_time')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppointmentFirestoreMapper.fromFirestore(d))
            .toList());
  }
}
