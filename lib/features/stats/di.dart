import 'package:barber/core/di.dart';
import 'package:barber/features/stats/data/repositories/stats_repository_impl.dart';
import 'package:barber/features/stats/domain/repositories/stats_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return StatsRepositoryImpl(firestore);
});
