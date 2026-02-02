import 'package:equatable/equatable.dart';

/// A time slot available for booking.
class TimeSlot extends Equatable {
  const TimeSlot({
    required this.time,
    required this.barberId,
  });

  final String time; // e.g. "09:00"
  final String barberId; // Barber who has this slot free

  @override
  List<Object?> get props => [time, barberId];
}

/// Groups time slots by period of day.
enum TimePeriod {
  morning, // < 12:00
  afternoon, // 12:00 - 17:00
  evening, // >= 17:00
}

extension TimePeriodExtension on TimePeriod {
  String get label {
    switch (this) {
      case TimePeriod.morning:
        return 'Morning';
      case TimePeriod.afternoon:
        return 'Afternoon';
      case TimePeriod.evening:
        return 'Evening';
    }
  }
}

/// Helper to determine time period from time string.
TimePeriod getTimePeriod(String time) {
  final parts = time.split(':');
  if (parts.isEmpty) return TimePeriod.morning;
  final hour = int.tryParse(parts[0]) ?? 0;
  if (hour < 12) return TimePeriod.morning;
  if (hour < 17) return TimePeriod.afternoon;
  return TimePeriod.evening;
}
