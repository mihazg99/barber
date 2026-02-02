import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/features/booking/data/mappers/appointment_firestore_mapper.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/booking/domain/entities/booked_slot.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Runs create-appointment + update-availability in a single Firestore transaction
/// so two users cannot book the same slot and we never have an appointment without
/// the slot marked booked.
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
    final appointmentRef =
        _firestore.collection(FirestoreCollections.appointments).doc(appointment.appointmentId);
    final availabilityRef =
        _firestore.collection(FirestoreCollections.availability).doc(docId);

    try {
      await _firestore.runTransaction((Transaction transaction) async {
        // 1. Read current availability
        final availabilitySnap = await transaction.get(availabilityRef);
        final existingSlots = _parseBookedSlots(availabilitySnap);

        // 2. Check slot still free (same logic as CalculateFreeSlots)
        if (_overlapsExisting(startTime, endTime, bufferTimeMinutes, existingSlots)) {
          throw FirebaseException(
            plugin: 'booking',
            code: 'slot-taken',
            message: 'This time slot was just booked by someone else. Please choose another.',
          );
        }

        // 3. Write appointment
        final appointmentData = AppointmentFirestoreMapper.toFirestore(appointment);
        appointmentData['created_at'] = FieldValue.serverTimestamp();
        transaction.set(appointmentRef, appointmentData);

        // 4. Write availability (append new slot)
        final newSlot = BookedSlot(
          start: startTime,
          end: endTime,
          appointmentId: appointment.appointmentId,
        );
        final updatedSlots = [...existingSlots, newSlot];
        final availabilityData = availabilitySnap.exists
            ? Map<String, dynamic>.from(availabilitySnap.data()!)
            : <String, dynamic>{
                'barber_id': barberId,
                'location_id': locationId,
                'date': dateStr,
              };
        availabilityData['booked_slots'] =
            updatedSlots.map((s) => s.toMap()).toList();
        transaction.set(availabilityRef, availabilityData);
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      if (e.code == 'slot-taken') {
        return Left(FirestoreFailure(e.message ?? 'Slot no longer available'));
      }
      return Left(FirestoreFailure('Booking failed: ${e.message}'));
    } catch (e) {
      return Left(FirestoreFailure('Booking failed: $e'));
    }
  }

  List<BookedSlot> _parseBookedSlots(DocumentSnapshot<Map<String, dynamic>> snap) {
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
}
