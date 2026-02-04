import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/features/booking/data/mappers/appointment_firestore_mapper.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/booking/domain/entities/booked_slot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Error code thrown when user already has an active (scheduled, future) appointment.
const _kUserHasActiveAppointment = 'user-has-active-appointment';

/// Runs create-appointment + update-availability in a single Firestore transaction
/// so two users cannot book the same slot and we never have an appointment without
/// the slot marked booked.
///
/// Appointments and availability (and user_booking_locks) must never be served from
/// cache: [AppointmentRepository] and [AvailabilityRepository] use GetOptions(source: Source.server)
/// so all devices see the same data and double-booking is prevented.
class BookingTransaction {
  BookingTransaction(this._firestore);

  final FirebaseFirestore _firestore;

  /// Creates the appointment and adds the slot to availability atomically.
  /// Fails if the slot is already taken (another client booked it).
  Future<Either<Failure, void>> createBookingWithSlot({
    required AppointmentEntity appointment,
    required String barberId,
    required String locationId,
    required String dateStr,
    required String startTime,
    required String endTime,
    required int bufferTimeMinutes,
  }) async {
    final docId = '${barberId}_$dateStr';
    final appointmentRef = _firestore
        .collection(FirestoreCollections.appointments)
        .doc(appointment.appointmentId);
    final availabilityRef = _firestore
        .collection(FirestoreCollections.availability)
        .doc(docId);

    try {
      await _firestore.runTransaction((Transaction transaction) async {
        // 0. Enforce one active appointment per user (atomic with slot booking)
        // Uses user_booking_locks/{userId} - transaction can only read docs by ref, not query.
        final lockRef = _firestore
            .collection(FirestoreCollections.userBookingLocks)
            .doc(appointment.userId);
        final lockSnap = await transaction.get(lockRef);
        final existingAppointmentId =
            lockSnap.exists && lockSnap.data() != null
                ? lockSnap.data()!['active_appointment_id'] as String?
                : null;
        if (existingAppointmentId != null && existingAppointmentId.isNotEmpty) {
          final apptRef = _firestore
              .collection(FirestoreCollections.appointments)
              .doc(existingAppointmentId);
          final apptSnap = await transaction.get(apptRef);
          if (apptSnap.exists && apptSnap.data() != null) {
            final data = apptSnap.data()!;
            final status = data['status'] as String? ?? '';
            final start = data['start_time'] as Timestamp?;
            final startTime = start?.toDate();
            if (status == AppointmentStatus.scheduled &&
                startTime != null &&
                startTime.isAfter(DateTime.now())) {
              throw FirebaseException(
                plugin: 'booking',
                code: _kUserHasActiveAppointment,
                message:
                    'You already have an upcoming appointment. Cancel or complete it before booking another.',
              );
            }
          }
        }

        // 1. Read current availability
        final availabilitySnap = await transaction.get(availabilityRef);
        final existingSlots = _parseBookedSlots(availabilitySnap);

        // 2. Check slot still free (same logic as CalculateFreeSlots)
        if (_overlapsExisting(
          startTime,
          endTime,
          bufferTimeMinutes,
          existingSlots,
        )) {
          throw FirebaseException(
            plugin: 'booking',
            code: 'slot-taken',
            message:
                'This time slot was just booked by someone else. Please choose another.',
          );
        }

        // 3. Write appointment
        final appointmentData = AppointmentFirestoreMapper.toFirestore(
          appointment,
        );
        appointmentData['created_at'] = FieldValue.serverTimestamp();
        transaction.set(appointmentRef, appointmentData);

        // 4. Write availability (append new slot)
        final newSlot = BookedSlot(
          start: startTime,
          end: endTime,
          appointmentId: appointment.appointmentId,
        );
        final updatedSlots = [...existingSlots, newSlot];
        final availabilityData =
            availabilitySnap.exists
                ? Map<String, dynamic>.from(availabilitySnap.data()!)
                : <String, dynamic>{
                  'barber_id': barberId,
                  'location_id': locationId,
                  'date': dateStr,
                };
        availabilityData['booked_slots'] =
            updatedSlots.map((s) => s.toMap()).toList();
        transaction.set(availabilityRef, availabilityData);

        // 5. Update user booking lock (one active appointment per user)
        transaction.set(lockRef, {
          'user_id': appointment.userId,
          'active_appointment_id': appointment.appointmentId,
        }, SetOptions(merge: true));
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      if (e.code == 'slot-taken') {
        return Left(FirestoreFailure(e.message ?? 'Slot no longer available'));
      }
      if (e.code == _kUserHasActiveAppointment) {
        return Left(
          FirestoreFailure(
            e.message ?? 'You already have an upcoming appointment.',
            code: _kUserHasActiveAppointment,
          ),
        );
      }
      return Left(FirestoreFailure('Booking failed: ${e.message}'));
    } catch (e) {
      return Left(FirestoreFailure('Booking failed: $e'));
    }
  }

  List<BookedSlot> _parseBookedSlots(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    if (!snap.exists || snap.data() == null) return [];
    final raw = snap.data()!['booked_slots'] as List<dynamic>?;
    if (raw == null) return [];
    final slots = <BookedSlot>[];
    for (final e in raw) {
      final slot = BookedSlot.fromMap(
        (e as Map<String, dynamic>?)?.cast<String, dynamic>(),
      );
      if (slot != null) slots.add(slot);
    }
    return slots;
  }

  bool _overlapsExisting(
    String startTime,
    String endTime,
    int bufferMinutes,
    List<BookedSlot> bookedSlots,
  ) {
    final slotStart = _timeToMinutes(startTime);
    final slotEnd = _timeToMinutes(endTime);

    for (final booked in bookedSlots) {
      final bookedStart = _timeToMinutes(booked.start);
      final bookedEnd = _timeToMinutes(booked.end);
      final blockedUntil = bookedEnd + bufferMinutes;
      if (slotStart < blockedUntil && slotEnd > bookedStart) return true;
    }
    return false;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  /// Cancels an appointment atomically: updates status, removes slot from
  /// availability, and clears user_booking_locks if this was the active one.
  /// [cancelHoursMinimum] when > 0: user must cancel at least that many hours
  /// before the appointment. Enforced server-side as well.
  Future<Either<Failure, void>> cancelAppointment(
    AppointmentEntity appointment, {
    int cancelHoursMinimum = 0,
  }) async {
    if (appointment.status != AppointmentStatus.scheduled) {
      return Left(
        FirestoreFailure(
          'Appointment is not scheduled and cannot be cancelled',
        ),
      );
    }
    if (cancelHoursMinimum > 0) {
      final hoursUntil =
          appointment.startTime.difference(DateTime.now()).inHours;
      if (hoursUntil < cancelHoursMinimum) {
        return Left(
          FirestoreFailure(
            'Cancellation must be done at least $cancelHoursMinimum hours before the appointment',
          ),
        );
      }
    }

    final dateStr = _formatDate(appointment.startTime);
    final docId = '${appointment.barberId}_$dateStr';
    final appointmentRef = _firestore
        .collection(FirestoreCollections.appointments)
        .doc(appointment.appointmentId);
    final availabilityRef = _firestore
        .collection(FirestoreCollections.availability)
        .doc(docId);
    final lockRef = _firestore
        .collection(FirestoreCollections.userBookingLocks)
        .doc(appointment.userId);

    try {
      await _firestore.runTransaction((Transaction transaction) async {
        // Firestore requires all reads before any writes.
        final availabilitySnap = await transaction.get(availabilityRef);
        final lockSnap = await transaction.get(lockRef);

        final existingSlots = _parseBookedSlots(availabilitySnap);
        final updatedSlots =
            existingSlots
                .where((s) => s.appointmentId != appointment.appointmentId)
                .toList();

        final availabilityData =
            availabilitySnap.exists && availabilitySnap.data() != null
                ? Map<String, dynamic>.from(availabilitySnap.data()!)
                : <String, dynamic>{
                  'barber_id': appointment.barberId,
                  'location_id': appointment.locationId,
                  'date': dateStr,
                };
        availabilityData['booked_slots'] =
            updatedSlots.map((s) => s.toMap()).toList();

        // All writes after reads.
        transaction.update(appointmentRef, {
          'status': AppointmentStatus.cancelled,
        });
        transaction.set(availabilityRef, availabilityData);
        if (lockSnap.exists &&
            lockSnap.data() != null &&
            lockSnap.data()!['active_appointment_id'] ==
                appointment.appointmentId) {
          transaction.update(lockRef, {
            'active_appointment_id': FieldValue.delete(),
          });
        }
      });
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to cancel appointment: $e'));
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
