import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
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
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.appointments}/${entity.appointmentId}',
        'set',
        () => _col.doc(entity.appointmentId).set(data),
      );
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
      final doc = await FirestoreLogger.logRead(
        '${FirestoreCollections.appointments}/$appointmentId',
        () => _col.doc(appointmentId).get(_serverOnly),
      );
      if (doc.data() == null) return const Right(null);
      return Right(AppointmentFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get appointment: $e'));
    }
  }

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getByUserId(
    String userId,
    String brandId,
  ) async {
    try {
      final snapshot = await FirestoreLogger.logRead(
        '${FirestoreCollections.appointments}?user_id=$userId&brand_id=$brandId',
        () => _col
            .where('user_id', isEqualTo: userId)
            .where('brand_id', isEqualTo: brandId)
            .get(const GetOptions(source: Source.server)),
      );
      final list =
          snapshot.docs
              .map((d) => AppointmentFirestoreMapper.fromFirestore(d))
              .toList();
      return Right(list);
    } catch (e) {
      return Left(FirestoreFailure('Failed to get appointments: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      await FirestoreLogger.logWrite(
        '${FirestoreCollections.appointments}/$appointmentId',
        'update',
        () => _col.doc(appointmentId).update({'status': status}),
      );
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to update appointment status: $e'));
    }
  }

  @override
  Future<Either<Failure, AppointmentEntity?>>
  getActiveScheduledAppointmentForUser(
    String userId,
    String brandId,
  ) async {
    try {
      final lockRef = _firestore
          .collection(FirestoreCollections.userBookingLocks)
          .doc('${userId}_${brandId}');
      final lockSnap = await FirestoreLogger.logRead(
        '${FirestoreCollections.userBookingLocks}/${userId}_$brandId',
        () => lockRef.get(_serverOnly),
      );
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
      return Left(
        FirestoreFailure(
          'Failed to get active appointment for user: $e',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> clearActiveAppointmentLock(
    String userId,
    String appointmentId,
  ) async {
    try {
      // Find the lock document that holds this appointment
      final lockSnap = await FirestoreLogger.logRead(
        '${FirestoreCollections.userBookingLocks}?user_id=$userId&appointment_id=$appointmentId',
        () => _firestore
            .collection(FirestoreCollections.userBookingLocks)
            .where('user_id', isEqualTo: userId)
            .where('active_appointment_id', isEqualTo: appointmentId)
            .get(_serverOnly),
      );

      for (final doc in lockSnap.docs) {
        await FirestoreLogger.logWrite(
          '${FirestoreCollections.userBookingLocks}/${doc.id}',
          'update',
          () => doc.reference.update({
            'active_appointment_id': FieldValue.delete(),
          }),
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(
        FirestoreFailure(
          'Failed to clear active appointment lock: $e',
        ),
      );
    }
  }

  @override
  Stream<String?> watchActiveAppointmentId(String userId) {
    return FirestoreLogger.logStream<String?>(
      '${FirestoreCollections.userBookingLocks}?user_id=$userId',
      _firestore
          .collection(FirestoreCollections.userBookingLocks)
          .where('user_id', isEqualTo: userId)
          .snapshots()
          .map((snap) {
            for (final doc in snap.docs) {
              final id = doc.data()['active_appointment_id'] as String?;
              if (id != null && id.isNotEmpty) return id;
            }
            return null;
          }),
    );
  }

  @override
  Stream<AppointmentEntity?> watchAppointment(String appointmentId) {
    return FirestoreLogger.logStream<AppointmentEntity?>(
      '${FirestoreCollections.appointments}/$appointmentId',
      _col.doc(appointmentId).snapshots().map((doc) {
        if (doc.data() == null) return null;
        return AppointmentFirestoreMapper.fromFirestore(doc);
      }),
    );
  }

  @override
  Stream<List<AppointmentEntity>> watchUpcomingAppointmentsForBarber(
    String barberId,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return FirestoreLogger.logStream<List<AppointmentEntity>>(
      '${FirestoreCollections.appointments}?barber_id=$barberId',
      _col
          .where('barber_id', isEqualTo: barberId)
          .where('status', isEqualTo: AppointmentStatus.scheduled)
          .where(
            'start_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
          )
          .orderBy('start_time')
          .snapshots()
          .map(
            (snap) {
              return snap.docs
                  .map((d) => AppointmentFirestoreMapper.fromFirestore(d))
                  .toList();
            },
          ),
    );
  }

  @override
  Stream<Either<Failure, AppointmentEntity?>> watchUpcomingAppointmentsForUser(
    String userId,
    String brandId,
  ) {
    return FirestoreLogger.logStream<Either<Failure, AppointmentEntity?>>(
      '${FirestoreCollections.appointments}?user_id=$userId&brand_id=$brandId',
      _col
          .where('user_id', isEqualTo: userId)
          .where('brand_id', isEqualTo: brandId)
          .where('status', isEqualTo: AppointmentStatus.scheduled)
          .orderBy('start_time')
          .snapshots()
          .map<Either<Failure, AppointmentEntity?>>((snapshot) {
            final now = DateTime.now();
            // Filter to remove stale appointments (those that have already ended).
            // We keep appointments that are ongoing (end time is in the future).
            final validDocs =
                snapshot.docs.where((doc) {
                  final data = doc.data();
                  // Ensure end_time exists and is valid
                  if (data['end_time'] == null) return false;
                  final end = (data['end_time'] as Timestamp).toDate();
                  return end.isAfter(now);
                }).toList();

            if (validDocs.isEmpty) {
              return const Right(null);
            }
            // Return the first valid appointment (earliest start time due to query order)
            return Right(
              AppointmentFirestoreMapper.fromFirestore(validDocs.first),
            );
          })
          .handleError(
            (e) => Left(FirestoreFailure('Failed to watch appointments: $e')),
          ),
    );
  }

  @override
  Stream<List<AppointmentEntity>> watchAppointmentsForBarberInRange(
    String barberId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return FirestoreLogger.logStream<List<AppointmentEntity>>(
      '${FirestoreCollections.appointments}?barber_id=$barberId&range=${startDate.toIso8601String()}_${endDate.toIso8601String()}',
      _col
          .where('barber_id', isEqualTo: barberId)
          .where('status', isEqualTo: AppointmentStatus.scheduled)
          .where(
            'start_time',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where(
            'start_time',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate),
          )
          .orderBy('start_time')
          .snapshots()
          .map(
            (snap) {
              return snap.docs
                  .map((d) => AppointmentFirestoreMapper.fromFirestore(d))
                  .toList();
            },
          ),
    );
  }
}
