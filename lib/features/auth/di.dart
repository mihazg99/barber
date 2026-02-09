import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/firebase/default_brand_id.dart' as brand_id;
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/brand/di.dart';
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
    onUserLoaded: (user) {
      ref.read(lastSignedInUserProvider.notifier).state = user;
    },
  );
});

final authNotifierProvider =
    StateNotifierProvider.autoDispose<AuthNotifier, BaseState<AuthFlowData>>((
      ref,
    ) {
      return AuthNotifier(
        ref.watch(authRepositoryProvider),
        ref.watch(userRepositoryProvider),
        onSignInUser: (user) {
          ref.read(lastSignedInUserProvider.notifier).state = user;
        },
        onPreSignIn: () async {
          await ref.read(defaultBrandProvider.future);
        },
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

/// Cached user from the last sign-in (used by auth flow). Cleared on signOut.
final lastSignedInUserProvider = StateProvider<UserEntity?>((ref) => null);

/// Set to true before signOut() so auth-dependent streams return null without subscribing; avoids PERMISSION_DENIED.
final isLoggingOutProvider = StateProvider<bool>((ref) => false);

/// Current user when authenticated. Single source: one Firestore stream (watchById).
/// Emits [lastSignedInUser] first when it matches uid so router sees profile complete immediately after sign-in (no redirect to profile setup).
/// When [isLoggingOutProvider] is true, returns Stream.value(null) so listeners are cancelled before auth becomes null.
final currentUserProvider = StreamProvider<UserEntity?>((ref) {
  if (ref.watch(isLoggingOutProvider)) return Stream.value(null);

  final uidAsync = ref.watch(currentUserIdProvider);

  // If auth is strictly loading (no value yet), keep this provider in loading state
  // by returning a future that doesn't complete.
  if (uidAsync.isLoading && !uidAsync.hasValue) {
    return Stream.fromFuture(Completer<UserEntity?>().future);
  }

  final uid = uidAsync.valueOrNull;
  if (uid == null || uid.isEmpty) return Stream.value(null);
  final last = ref.watch(lastSignedInUserProvider);
  final repo = ref.watch(userRepositoryProvider);
  if (last != null && last.userId == uid) {
    // Emit cached user immediately so isProfileComplete is true and returning users go to home, then live updates.
    return Stream.value(last).asyncExpand((_) => repo.watchById(uid));
  }
  return repo.watchById(uid);
});

/// Alias for code that referred to the old stream-only provider.
final currentUserStreamProvider = currentUserProvider;

/// True when authenticated and profile has both fullName and phone set. Used by router redirect.
/// Uses [lastSignedInUser] when it matches current uid so redirect is correct immediately after sign-in (no profile-setup flash).
final isProfileCompleteProvider = Provider<bool>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUserId;
  final last = ref.watch(lastSignedInUserProvider);
  if (uid != null && last != null && last.userId == uid) {
    return last.fullName.trim().isNotEmpty && last.phone.trim().isNotEmpty;
  }
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user != null &&
      user.fullName.trim().isNotEmpty &&
      user.phone.trim().isNotEmpty;
});

/// True when user has barber or superadmin role. They navigate to dashboard, not main app.
/// Uses [lastSignedInUser] when it matches current uid so redirect is correct immediately after sign-in.
final isStaffProvider = Provider<bool>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUserId;
  final last = ref.watch(lastSignedInUserProvider);
  if (uid != null && last != null && last.userId == uid) {
    return last.role.isStaff;
  }
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.role.isStaff ?? false;
});
