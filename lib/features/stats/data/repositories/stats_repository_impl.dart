import 'package:dartz/dartz.dart';

import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/firebase/firestore_logger.dart';
import 'package:barber/features/stats/data/mappers/daily_stats_firestore_mapper.dart';
import 'package:barber/features/stats/data/mappers/monthly_stats_firestore_mapper.dart';
import 'package:barber/features/stats/domain/entities/dashboard_stats_entity.dart';
import 'package:barber/features/stats/domain/repositories/stats_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatsRepositoryImpl implements StatsRepository {
  StatsRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Either<Failure, DashboardStatsEntity>> getDashboardStats(
    String locationId,
    DateTime date,
  ) async {
    final dateKey = _dateKey(date);
    final monthKey = _monthKey(date);

    final locationRef = _firestore
        .collection(FirestoreCollections.locations)
        .doc(locationId);
    final dailyRef = locationRef
        .collection(FirestoreCollections.dailyStats)
        .doc(dateKey);
    final monthlyRef = locationRef
        .collection(FirestoreCollections.monthlyStats)
        .doc(monthKey);

    try {
      final results = await FirestoreLogger.logRead(
        'stats: daily=$dateKey, monthly=$monthKey',
        () => Future.wait([dailyRef.get(), monthlyRef.get()]),
      );

      final dailySnap = results[0];
      final monthlySnap = results[1];

      final dailyStats = dailySnap.exists
          ? DailyStatsFirestoreMapper.fromFirestore(dailySnap)
          : null;
      final monthlyStats = monthlySnap.exists
          ? MonthlyStatsFirestoreMapper.fromFirestore(monthlySnap)
          : null;

      return Right(DashboardStatsEntity(
        dailyStats: dailyStats,
        monthlyStats: monthlyStats,
      ));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get dashboard stats: $e'));
    }
  }

  static String _dateKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _monthKey(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    return '$y-$m';
  }
}
