import 'package:equatable/equatable.dart';

/// Daily aggregated stats per location. Path: locations/{location_id}/daily_stats/{YYYY-MM-DD}
class DailyStatsEntity extends Equatable {
  const DailyStatsEntity({
    required this.dateKey,
    required this.totalRevenue,
    required this.appointmentsCount,
    required this.newCustomers,
    required this.noShows,
    required this.serviceBreakdown,
  });

  /// Document ID: YYYY-MM-DD
  final String dateKey;

  final num totalRevenue;
  final int appointmentsCount;
  final int newCustomers;
  final int noShows;

  /// Map of service_id -> count of appointments including that service.
  final Map<String, int> serviceBreakdown;

  @override
  List<Object?> get props => [
        dateKey,
        totalRevenue,
        appointmentsCount,
        newCustomers,
        noShows,
        serviceBreakdown,
      ];
}
