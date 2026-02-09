import 'package:equatable/equatable.dart';

/// Time-off period for a barber (vacation, sick leave, personal time).
/// doc_id: auto-generated
class TimeOffEntity extends Equatable {
  const TimeOffEntity({
    required this.timeOffId,
    required this.barberId,
    required this.brandId,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.createdAt,
  });

  final String timeOffId;
  final String barberId;
  final String brandId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason; // 'vacation', 'sick', 'personal'
  final DateTime createdAt;

  /// Check if this time-off period covers a specific date.
  bool coversDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    return (dateOnly.isAtSameMomentAs(startOnly) ||
            dateOnly.isAfter(startOnly)) &&
        (dateOnly.isAtSameMomentAs(endOnly) || dateOnly.isBefore(endOnly));
  }

  @override
  List<Object?> get props => [
    timeOffId,
    barberId,
    brandId,
    startDate,
    endDate,
    reason,
    createdAt,
  ];
}
