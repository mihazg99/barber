import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:barber/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:barber/features/auth/domain/entities/auth_step.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/auth/domain/entities/user_role.dart';
import 'package:barber/features/auth/domain/repositories/auth_repository.dart';
import 'package:barber/features/auth/data/repositories/user_repository_impl.dart';
import 'package:barber/features/auth/domain/repositories/user_repository.dart';
import 'package:barber/features/auth/presentation/bloc/auth_notifier.dart';
import 'package:barber/features/auth/presentation/bloc/login_overlay_notifier.dart';
import 'package:barber/core/push/push_notification_notifier.dart';
import 'package:barber/core/push/push_notification_data.dart';
import 'package:barber/core/settings/notification_settings_notifier.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Effective role for navigation and client-side access control.
/// This is derived from the raw [UserRole] and the locked brand context.
enum EffectiveUserRole {
  guest,
  user,
  barber,
  superadmin,
}

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
  return AuthRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
    ref.watch(userRepositoryProvider),
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

/// Effective user ID: Firebase UID when signed in, otherwise a persistent guest ID from local storage.
/// Use this for any flow that should work for both guests and signed-in users (e.g. local state, drafts).
final effectiveUserIdProvider = Provider<String>((ref) {
  final uid = ref.watch(currentUserIdProvider).valueOrNull;
  if (uid != null && uid.isNotEmpty) return uid;
  return ref.watch(guestStorageProvider).getOrCreateGuestId();
});

/// True when the current user is a guest (no Firebase auth).
final isGuestProvider = Provider<bool>((ref) {
  final uid = ref.watch(currentUserIdProvider).valueOrNull;
  return uid == null || uid.isEmpty;
});

/// Flag to indicate guest is intentionally trying to login (clicked Login button).
/// Prevents router from redirecting away from auth page.
final isGuestLoginIntentProvider = StateProvider<bool>((ref) => false);

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
  final uid = ref.watch(currentUserIdProvider).valueOrNull;
  final last = ref.watch(lastSignedInUserProvider);

  if (uid != null && last != null && last.userId == uid) {
    final complete =
        last.fullName.trim().isNotEmpty && last.phone.trim().isNotEmpty;
    print(
      'DEBUG: isProfileCompleteProvider (from LAST) uid=$uid, last=${last.fullName}|${last.phone}, complete=$complete',
    );
    return complete;
  }

  final user = ref.watch(currentUserProvider).valueOrNull;
  final complete =
      user != null &&
      user.fullName.trim().isNotEmpty &&
      user.phone.trim().isNotEmpty;
  print(
    'DEBUG: isProfileCompleteProvider (from USER) uid=$uid, user=${user?.fullName}|${user?.phone}, complete=$complete',
  );
  return complete;
});

/// Effective role taking into account the locked brand context.
/// - guest: no authenticated user or no locked brand
/// - user: regular client, or staff user whose brand does not match the locked brand
/// - barber / superadmin: staff whose [user.brandId] matches the locked brand
final effectiveUserRoleProvider = Provider<EffectiveUserRole>((ref) {
  // 1. Get User
  UserEntity? user;
  final uid = ref.watch(authRepositoryProvider).currentUserId;
  final last = ref.watch(lastSignedInUserProvider);
  if (uid != null && last != null && last.userId == uid) {
    user = last;
  } else {
    user = ref.watch(currentUserProvider).valueOrNull;
  }

  if (user == null) return EffectiveUserRole.guest;

  // Brand context: if there is no locked brand yet, treat as guest for role-gated flows.
  final lockedBrandId = ref.watch(lockedBrandIdProvider);
  if (lockedBrandId == null || lockedBrandId.isEmpty) {
    return EffectiveUserRole.guest;
  }

  // Non-staff users are always treated as regular users.
  if (!user.role.isStaff) return EffectiveUserRole.user;

  // Staff but mismatched brand: treat as regular user for this brand context.
  if (user.brandId.isEmpty || user.brandId != lockedBrandId) {
    return EffectiveUserRole.user;
  }

  // Staff with matching brand: respect their staff role.
  switch (user.role) {
    case UserRole.barber:
      return EffectiveUserRole.barber;
    case UserRole.superadmin:
      return EffectiveUserRole.superadmin;
    case UserRole.user:
      return EffectiveUserRole.user;
  }
});

/// True when user has barber or superadmin effective role. They navigate to dashboard, not main app.
final isStaffProvider = Provider<bool>((ref) {
  final role = ref.watch(effectiveUserRoleProvider);
  return role == EffectiveUserRole.barber ||
      role == EffectiveUserRole.superadmin;
});

/// Login overlay notifier for showing/hiding the contextual login modal.
final loginOverlayNotifierProvider = StateNotifierProvider.autoDispose<
  LoginOverlayNotifier,
  BaseState<LoginOverlayState>
>((
  ref,
) {
  return LoginOverlayNotifier();
});

/// FCM push notifications: permission, token, foreground/initial message.
/// Token is synced to the current user document when signed in.
final pushNotificationNotifierProvider = StateNotifierProvider.autoDispose<
  PushNotificationNotifier,
  BaseState<PushNotificationData>
>((ref) {
  return PushNotificationNotifier(
    FirebaseMessaging.instance,
  );
});

/// Keeps push notifier alive and syncs FCM token to user when notifications are
/// enabled; clears token when disabled. Watch in app root.
final pushNotificationBootstrapProvider = Provider<void>((ref) {
  ref.watch(pushNotificationNotifierProvider);
  final settingsState = ref.watch(notificationSettingsNotifierProvider);
  final notificationsEnabled =
      settingsState is BaseData<bool> ? settingsState.data : true;

  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.valueOrNull;
  final userId = user?.userId;

  final pushState = ref.watch(pushNotificationNotifierProvider);
  final pushData =
      pushState is BaseData<PushNotificationData> ? pushState.data : null;
  final newToken = pushData?.fcmToken;

  if (userId == null || userId.isEmpty) return;

  final userRepo = ref.read(userRepositoryProvider);

  if (notificationsEnabled && newToken != null && newToken.isNotEmpty) {
    // Only update if token has changed
    if (user?.fcmToken != newToken) {
      userRepo.updateFcmToken(userId, newToken);
    }
  } else if (!notificationsEnabled) {
    // Only clear if not already cleared
    if (user?.fcmToken != null && user!.fcmToken.isNotEmpty) {
      userRepo.updateFcmToken(userId, '');
    }
  }
});
