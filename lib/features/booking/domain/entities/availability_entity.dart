import 'package:barber/features/booking/domain/entities/booked_slot.dart';
import 'package:equatable/equatable.dart';

/// Pre-calculated slots for fast booking.
/// doc_id: barber_id_YYYY-MM-DD (e.g. luka_2026-05-10)
class AvailabilityEntity extends Equatable {
  const AvailabilityEntity({
    required this.docId,
    required this.barberId,
    required this.locationId,
    required this.date,
    required this.bookedSlots,
  });

  final String docId;
  final String barberId;
  final String locationId;
  final String date; // YYYY-MM-DD
  final List<BookedSlot> bookedSlots;

  @override
  List<Object?> get props => [docId, barberId, locationId, date, bookedSlots];
}
