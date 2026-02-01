import 'package:barber/core/di.dart';
import 'package:barber/features/services/data/repositories/service_repository_impl.dart';
import 'package:barber/features/services/domain/repositories/service_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return ServiceRepositoryImpl(firestore);
});
