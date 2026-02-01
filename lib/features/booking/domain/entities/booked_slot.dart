import 'package:equatable/equatable.dart';

/// A single booked slot in the availability document.
class BookedSlot extends Equatable {
  const BookedSlot({
    required this.start,
    required this.end,
    required this.appointmentId,
  });

  final String start; // e.g. "08:00"
  final String end; // e.g. "08:35"
  final String appointmentId;

  Map<String, dynamic> toMap() => {
        'start': start,
        'end': end,
        'appointment_id': appointmentId,
      };

  static BookedSlot? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final start = map['start'] as String?;
    final end = map['end'] as String?;
    final appointmentId = map['appointment_id'] as String?;
    if (start == null || end == null || appointmentId == null) return null;
    return BookedSlot(start: start, end: end, appointmentId: appointmentId);
  }

  @override
  List<Object?> get props => [start, end, appointmentId];
}
