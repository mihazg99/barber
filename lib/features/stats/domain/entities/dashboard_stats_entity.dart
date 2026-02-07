import 'package:barber/features/stats/domain/entities/daily_stats_entity.dart';
import 'package:barber/features/stats/domain/entities/monthly_stats_entity.dart';

/// Combined stats for admin dashboard. Fetched from pre-aggregated daily_stats and monthly_stats.
class DashboardStatsEntity {
  const DashboardStatsEntity({
    required this.dailyStats,
    required this.monthlyStats,
  });

  final DailyStatsEntity? dailyStats;
  final MonthlyStatsEntity? monthlyStats;

  /// Average ticket value (total_revenue / appointments_count) for today.
  /// Returns null if no appointments or no daily stats.
  double? get averageTicketValueToday {
    final daily = dailyStats;
    if (daily == null || daily.appointmentsCount <= 0) return null;
    return daily.totalRevenue / daily.appointmentsCount;
  }

  /// Average ticket value for the month.
  double? get averageTicketValueMonthly {
    final monthly = monthlyStats;
    if (monthly == null) return null;
    final total = monthly.barberAppointments.values.fold<int>(0, (a, b) => a + b);
    if (total <= 0) return null;
    return monthly.totalRevenue / total;
  }
}
