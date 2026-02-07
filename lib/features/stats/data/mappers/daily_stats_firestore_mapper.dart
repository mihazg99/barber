import 'package:barber/features/stats/domain/entities/daily_stats_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [DailyStatsEntity].
/// Path: locations/{location_id}/daily_stats/{YYYY-MM-DD}
class DailyStatsFirestoreMapper {
  static DailyStatsEntity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final serviceBreakdownRaw = data['service_breakdown'] as Map<String, dynamic>?;
    final serviceBreakdown = <String, int>{};
    if (serviceBreakdownRaw != null) {
      for (final e in serviceBreakdownRaw.entries) {
        final v = e.value;
        if (v is num) {
          serviceBreakdown[e.key] = v.toInt();
        }
      }
    }

    return DailyStatsEntity(
      dateKey: doc.id,
      totalRevenue: (data['total_revenue'] as num?)?.toDouble() ?? 0.0,
      appointmentsCount: (data['appointments_count'] as num?)?.toInt() ?? 0,
      newCustomers: (data['new_customers'] as num?)?.toInt() ?? 0,
      noShows: (data['no_shows'] as num?)?.toInt() ?? 0,
      serviceBreakdown: serviceBreakdown,
    );
  }
}
