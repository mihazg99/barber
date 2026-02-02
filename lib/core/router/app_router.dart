import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/auth_step.dart';
import 'package:barber/features/booking/presentation/pages/booking_page.dart';
import 'package:barber/features/home/presentation/pages/home_page.dart';
import 'package:barber/features/inventory/presentation/pages/add_item_page.dart';
import 'package:barber/features/inventory/presentation/pages/inventory_page.dart';
import 'package:barber/features/loyalty/presentation/pages/loyalty_page.dart';
import 'package:barber/features/onboarding/di.dart';
import 'package:barber/features/onboarding/presentation/pages/onboarding_page.dart';

import 'package:barber/features/auth/presentation/pages/auth_page.dart';

import 'app_routes.dart';

class _AuthRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Notify to re-run router redirect (e.g. after profile update).
final routerRefreshNotifierProvider = ChangeNotifierProvider<_AuthRefreshNotifier>((ref) {
  return _AuthRefreshNotifier();
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  ref.listen(isAuthenticatedProvider, (prev, next) {
    if (next.valueOrNull == true) {
      ref.invalidate(currentUserProvider);
      // Delay so verifyOtp's setData(profile step) runs first for new users; then redirect
      // sends returning users (profile complete) to home and keeps new users on auth for profile step.
      Future.delayed(const Duration(milliseconds: 200), () {
        refreshNotifier.notify();
      });
    }
  });

  return GoRouter(
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Use container from context so we don't use ref during "dependency changed"
      // (e.g. when refreshNotifier.notify() runs from ref.listen), which would throw.
      final container = ProviderScope.containerOf(context);
      final onboardingCompleted = container.read(onboardingHasCompletedProvider);
      final isAuthenticated = container.read(isAuthenticatedProvider).valueOrNull ?? false;
      final isProfileComplete = container.read(isProfileCompleteProvider);
      final authState = container.read(authNotifierProvider);
      final authData = authState is BaseData ? (authState as BaseData).data : null;
      final isInProfileStep = authData is AuthFlowData && authData.isProfileInfo;

      final path = state.uri.path;
      if (!onboardingCompleted && path != AppRoute.onboarding.path) {
        return AppRoute.onboarding.path;
      }
      if (onboardingCompleted && path == AppRoute.onboarding.path) {
        return isAuthenticated ? AppRoute.home.path : AppRoute.auth.path;
      }
      if (onboardingCompleted && !isAuthenticated && path != AppRoute.auth.path) {
        return AppRoute.auth.path;
      }
      if (isAuthenticated && path == AppRoute.auth.path) {
        // Stay on auth when profile incomplete or when showing profile step (avoid redirect race).
        if (isInProfileStep || !isProfileComplete) return null;
        return AppRoute.home.path;
      }
      return null;
    },
    routes: [
      GoRoute(
        name: AppRoute.onboarding.name,
        path: AppRoute.onboarding.path,
        pageBuilder: (context, state) =>
            NoTransitionPage(child: const OnboardingPage()),
      ),
      GoRoute(
        name: AppRoute.auth.name,
        path: AppRoute.auth.path,
        pageBuilder: (context, state) =>
            NoTransitionPage(child: const AuthPage()),
      ),
      GoRoute(
        name: AppRoute.home.name,
        path: AppRoute.home.path,
        pageBuilder:
            (context, state) => NoTransitionPage(child: const HomePage()),
      ),
      GoRoute(
        name: AppRoute.booking.name,
        path: AppRoute.booking.path,
        pageBuilder:
            (context, state) => NoTransitionPage(child: const BookingPage()),
      ),
      GoRoute(
        name: AppRoute.loyalty.name,
        path: AppRoute.loyalty.path,
        pageBuilder:
            (context, state) => NoTransitionPage(child: const LoyaltyPage()),
      ),
    GoRoute(
      name: AppRoute.inventory.name,
      path: AppRoute.inventory.path,
      pageBuilder:
          (context, state) => NoTransitionPage(child: const InventoryPage()),
    ),
    GoRoute(
      name: AppRoute.statistics.name,
      path: AppRoute.statistics.path,
      pageBuilder:
          (context, state) => NoTransitionPage(child: const InventoryPage()),
    ),
      GoRoute(
        name: AppRoute.addNewItem.name,
        path: AppRoute.addNewItem.path,
        pageBuilder: (context, state) => NoTransitionPage(child: AddItemPage()),
      ),
    ],
  );
});

