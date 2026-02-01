import 'package:barber/core/di.dart';
import 'package:barber/features/auth/data/repositories/user_repository_impl.dart';
import 'package:barber/features/auth/domain/repositories/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return UserRepositoryImpl(firestore);
});
