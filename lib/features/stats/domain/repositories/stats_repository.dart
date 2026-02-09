import 'package:dartz/dartz.dart';

import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/stats/domain/entities/dashboard_stats_entity.dart';

abstract class StatsRepository {
  /// Fetches the daily_stats document for [date] and monthly_stats for the
  /// containing month. Optimized: two document reads, no appointments query.
  Future<Either<Failure, DashboardStatsEntity>> getDashboardStats(
    String locationId,
    DateTime date,
  );
}
