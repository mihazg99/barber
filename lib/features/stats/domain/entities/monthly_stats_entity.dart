import 'package:equatable/equatable.dart';

/// Monthly aggregated stats per location. Path: locations/{location_id}/monthly_stats/{YYYY-MM}
class MonthlyStatsEntity extends Equatable {
  const MonthlyStatsEntity({
    required this.monthKey,
    required this.totalRevenue,
    this.topBarberId,
    this.retentionRate = 0.0,
    this.barberAppointments = const {},
  });

  /// Document ID: YYYY-MM
  final String monthKey;

  final num totalRevenue;

  /// Barber with highest appointment count this month. Derived from [barberAppointments].
  final String? topBarberId;

  /// Percentage of returning customers (0.0–1.0). Computed by batch job.
  final double retentionRate;

  /// Map of barber_id -> appointment count. Event-sourced for client to derive top barber.
  final Map<String, int> barberAppointments;

  @override
  List<Object?> get props => [
        monthKey,
        totalRevenue,
        topBarberId,
        retentionRate,
        barberAppointments,
      ];
}
