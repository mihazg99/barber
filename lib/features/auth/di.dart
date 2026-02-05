import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/firebase/default_brand_id.dart' as brand_id;
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:barber/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:barber/features/auth/domain/entities/auth_step.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/auth/domain/repositories/auth_repository.dart';
import 'package:barber/features/auth/data/repositories/user_repository_impl.dart';
import 'package:barber/features/auth/domain/repositories/user_repository.dart';
import 'package:barber/features/auth/presentation/bloc/auth_notifier.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(firebaseFirestoreProvider));
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    ref.watch(firebaseAuthProvider),
    ref.watch(googleSignInProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final configBrandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(userRepositoryProvider),
    configBrandId.isNotEmpty ? configBrandId : brand_id.fallbackBrandId,
  );
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, BaseState<AuthFlowData>>((ref) {
      return AuthNotifier(
        ref.watch(authRepositoryProvider),
        ref.watch(userRepositoryProvider),
      );
    });

/// True when user is signed in. Used by router redirect.
final isAuthenticatedProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(authRepositoryProvider)
      .authStateChanges
      .map((uid) => uid != null);
});

/// Current Firebase Auth UID, or null when signed out. Use this (not .currentUserId) so
/// upcoming-appointment and other providers re-run when auth state actually changes.
final currentUserIdProvider = StreamProvider<String?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Current user when authenticated. Refetches when auth state changes.
final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  ref.watch(isAuthenticatedProvider);
  final uid = ref.watch(authRepositoryProvider).currentUserId;
  if (uid == null) return null;
  final result = await ref.watch(userRepositoryProvider).getById(uid);
  return result.fold((_) => null, (u) => u);
});

/// Current user as a stream so loyalty points update in real time when barber awards points (e.g. on home screen).
final currentUserStreamProvider = StreamProvider<UserEntity?>((ref) {
  final uidAsync = ref.watch(currentUserIdProvider);
  final uid = uidAsync.valueOrNull;
  if (uid == null || uid.isEmpty) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchById(uid);
});

/// True when authenticated and profile has fullName set. Used by router redirect.
final isProfileCompleteProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  return user != null && user.fullName.trim().isNotEmpty;
});

/// True when user has barber or superadmin role. They navigate to dashboard, not main app.
final isStaffProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  return user?.role.isStaff ?? false;
});
