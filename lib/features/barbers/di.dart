import 'package:barber/core/di.dart';
import 'package:barber/features/barbers/data/repositories/barber_repository_impl.dart';
import 'package:barber/features/barbers/domain/repositories/barber_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final barberRepositoryProvider = Provider<BarberRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return BarberRepositoryImpl(firestore);
});
