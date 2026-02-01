import 'package:barber/core/di.dart';
import 'package:barber/features/locations/data/repositories/location_repository_impl.dart';
import 'package:barber/features/locations/domain/repositories/location_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return LocationRepositoryImpl(firestore);
});
