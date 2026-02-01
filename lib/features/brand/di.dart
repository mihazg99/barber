import 'package:barber/core/di.dart';
import 'package:barber/features/brand/data/repositories/brand_repository_impl.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return BrandRepositoryImpl(firestore);
});
