import 'package:barber/features/stats/domain/entities/monthly_stats_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps Firestore documents ↔ [MonthlyStatsEntity].
/// Path: locations/{location_id}/monthly_stats/{YYYY-MM}
class MonthlyStatsFirestoreMapper {
  static MonthlyStatsEntity fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final barberAppointmentsRaw =
        data['barber_appointments'] as Map<String, dynamic>?;
    final barberAppointments = <String, int>{};
    if (barberAppointmentsRaw != null) {
      for (final e in barberAppointmentsRaw.entries) {
        final v = e.value;
        if (v is num) {
          barberAppointments[e.key] = v.toInt();
        }
      }
    }

    final topBarberId = data['top_barber_id'] as String?;
    String? resolvedTopBarberId = topBarberId;
    if (resolvedTopBarberId == null && barberAppointments.isNotEmpty) {
      resolvedTopBarberId = barberAppointments.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    return MonthlyStatsEntity(
      monthKey: doc.id,
      totalRevenue: (data['total_revenue'] as num?)?.toDouble() ?? 0.0,
      topBarberId: resolvedTopBarberId,
      retentionRate: (data['retention_rate'] as num?)?.toDouble() ?? 0.0,
      barberAppointments: barberAppointments,
    );
  }
}
