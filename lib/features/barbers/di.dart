import 'package:barber/core/di.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/user_role.dart';
import 'package:barber/features/barbers/data/repositories/barber_repository_impl.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/barbers/domain/repositories/barber_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final barberRepositoryProvider = Provider<BarberRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return BarberRepositoryImpl(firestore);
});

/// Current barber record when logged-in user has barber role and a barber doc
/// is linked via user_id. Null for non-barbers or when no barber record is linked.
final currentBarberProvider = FutureProvider<BarberEntity?>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null || user.role != UserRole.barber) return null;
  final result = await ref.watch(barberRepositoryProvider).getByUserId(user.userId);
  return result.fold((_) => null, (b) => b);
});
