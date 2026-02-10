import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/auth_step.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/booking/presentation/pages/booking_page.dart';
import 'package:barber/features/booking/presentation/pages/edit_booking_page.dart';
import 'package:barber/features/booking/presentation/pages/manage_booking_page.dart';
import 'package:barber/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:barber/features/dashboard/presentation/pages/location_form_page.dart';
import 'package:barber/features/dashboard/presentation/pages/barber_form_page.dart';
import 'package:barber/features/dashboard/presentation/pages/reward_form_page.dart';
import 'package:barber/features/dashboard/presentation/pages/service_form_page.dart';
import 'package:barber/features/dashboard/presentation/pages/redeem_reward_scan_page.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/rewards/domain/entities/reward_entity.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/presentation/pages/home_page.dart';
import 'package:barber/features/inventory/presentation/pages/add_item_page.dart';
import 'package:barber/features/inventory/presentation/pages/inventory_page.dart';
import 'package:barber/features/loyalty/presentation/pages/loyalty_page.dart';
import 'package:barber/features/onboarding/di.dart';
import 'package:barber/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:barber/features/brand_selection/di.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/brand_selection/presentation/pages/brand_onboarding_page.dart';
import 'package:barber/features/brand_selection/presentation/pages/brand_switcher_page.dart';

import 'package:barber/core/di.dart';
import 'package:barber/features/auth/presentation/pages/auth_page.dart';
import 'package:barber/features/splash/presentation/pages/splash_page.dart';

import 'app_routes.dart';

// Track first run globally to persist across provider rebuilds (e.g. on logout)
bool _isFirstRun = true;

final goRouterProvider = Provider<GoRouter>((ref) {
  // Initialize persistence listener for selected brand override
  initSelectedBrandPersistence(ref);

  final refreshNotifier = ref.watch(routerRefreshNotifierProvider);

  ref.listen(isAuthenticatedProvider, (prev, next) {
    if (next.valueOrNull == true) {
      ref.invalidate(currentUserProvider);
      ref.invalidate(upcomingAppointmentProvider);
      // Delay so verifyOtp's setData(profile step) runs first for new users; then redirect
      // sends returning users (profile complete) to home and keeps new users on auth for profile step.
      Future.delayed(const Duration(milliseconds: 200), () {
        refreshNotifier.notify();
      });
    } else if (next.valueOrNull == false) {
      refreshNotifier.notify();
    }
  });

  // When currentUser loads after sign-in, redirect again so isProfileComplete is up to date
  // (returning users with profile complete can then navigate to home).
  ref.listen(currentUserProvider, (prev, next) {
    if (ref.read(isAuthenticatedProvider).valueOrNull == true &&
        next.valueOrNull != null) {
      ref.invalidate(upcomingAppointmentProvider);
      Future.microtask(() => refreshNotifier.notify());
    }
  });

  // When repo sets lastSignedInUser (Google/Apple/OTP sign-in), invalidate currentUser so stream emits cache and router can redirect to home (not profile setup).
  ref.listen(lastSignedInUserProvider, (prev, next) {
    if (next != null && ref.read(isAuthenticatedProvider).valueOrNull == true) {
      ref.invalidate(currentUserProvider);
      Future.microtask(() => refreshNotifier.notify());
    }
  });

  // Listen for brand state changes to trigger redirects (onboarding/switcher)
  ref.listen(userBrandsProvider, (_, next) {
    if (!next.isLoading) {
      refreshNotifier.notify();
    }
  });

  ref.listen(selectedBrandIdProvider, (_, __) => refreshNotifier.notify());

  return GoRouter(
    initialLocation: AppRoute.auth.path,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Force splash screen on first run (app startup) when landing on default route,
      // but allow Auth as fallback for future refreshes to avoid splash flash.
      if (_isFirstRun && state.uri.path == AppRoute.auth.path) {
        _isFirstRun = false;
        return AppRoute.splash.path;
      }
      _isFirstRun = false;

      // Use container from context so we don't use ref during "dependency changed"
      // (e.g. when refreshNotifier.notify() runs from ref.listen), which would throw.
      final container = ProviderScope.containerOf(context);
      final onboardingCompleted = container.read(
        onboardingHasCompletedProvider,
      );
      final isAuthenticated =
          container.read(isAuthenticatedProvider).valueOrNull ?? false;
      final isProfileComplete = container.read(isProfileCompleteProvider);
      final authState = container.read(authNotifierProvider);
      final authData =
          authState is BaseData ? (authState as BaseData).data : null;
      final isInProfileStep =
          authData is AuthFlowData && authData.isProfileInfo;

      final isStaff = container.read(isStaffProvider);
      final path = state.uri.path;
      final location = state.uri.toString();

      // Splash: stay until we know destination, then redirect
      if (path == AppRoute.splash.path) {
        if (!onboardingCompleted) return AppRoute.onboarding.path;
        final isAuthAsync = container.read(isAuthenticatedProvider);
        if (isAuthAsync.isLoading) return null;
        if (isAuthAsync.valueOrNull != true) return AppRoute.auth.path;
        final userAsync = container.read(currentUserProvider);
        if (userAsync.isLoading) return null;
        if (!isProfileComplete) return AppRoute.auth.path;
        return isStaff ? AppRoute.dashboard.path : AppRoute.home.path;
      }

      // Firebase auth callback deep link (e.g. after login/verify) – not an app route; send to correct screen.
      if (location.contains('firebaseauth') ||
          location.contains('auth/callback')) {
        if (!onboardingCompleted) return AppRoute.onboarding.path;
        if (isAuthenticated && isProfileComplete) {
          return isStaff ? AppRoute.dashboard.path : AppRoute.home.path;
        }
        return AppRoute.auth.path;
      }
      if (!onboardingCompleted && path != AppRoute.onboarding.path) {
        return AppRoute.onboarding.path;
      }
      if (onboardingCompleted && path == AppRoute.onboarding.path) {
        if (isAuthenticated) {
          return isProfileComplete
              ? (isStaff ? AppRoute.dashboard.path : AppRoute.home.path)
              : AppRoute.auth.path;
        }
        return AppRoute.auth.path;
      }
      if (onboardingCompleted &&
          !isAuthenticated &&
          path != AppRoute.auth.path) {
        return AppRoute.auth.path;
      }
      // Authenticated but profile incomplete: send to auth (setup profile).
      // Skip redirect while currentUser is still loading so we don't block navigation to booking etc.
      if (onboardingCompleted &&
          isAuthenticated &&
          !isProfileComplete &&
          path != AppRoute.auth.path) {
        final userAsync = container.read(currentUserProvider);
        if (userAsync.isLoading) return AppRoute.auth.path;
        return AppRoute.auth.path;
      }
      if (isAuthenticated && path == AppRoute.auth.path) {
        // Stay on auth when profile incomplete or when showing profile step (avoid redirect race).
        if (isInProfileStep || !isProfileComplete) return null;
        return isStaff ? AppRoute.dashboard.path : AppRoute.home.path;
      }

      // Brand selection flow: check after authentication + profile complete
      if (isAuthenticated && isProfileComplete) {
        final userBrandsAsync = container.read(userBrandsProvider);

        // Wait for brands to load
        if (userBrandsAsync.isLoading) return null;

        final userBrands = userBrandsAsync.valueOrNull ?? [];
        final selectedBrandId = container.read(selectedBrandIdProvider);

        // No brands → redirect to brand onboarding
        if (userBrands.isEmpty && path != AppRoute.brandOnboarding.path) {
          return AppRoute.brandOnboarding.path;
        }

        // Has brands but no selection → redirect to brand switcher
        if (userBrands.isNotEmpty &&
            selectedBrandId == null &&
            path != AppRoute.brandSwitcher.path &&
            path != AppRoute.brandOnboarding.path) {
          return AppRoute.brandSwitcher.path;
        }

        // Allow brand onboarding/switcher pages
        if (path == AppRoute.brandOnboarding.path ||
            path == AppRoute.brandSwitcher.path) {
          return null;
        }

        // Staff must use dashboard; regular users must use home
        if (isStaff && path == AppRoute.home.path)
          return AppRoute.dashboard.path;
        if (!isStaff && path == AppRoute.dashboard.path)
          return AppRoute.home.path;
      }
      return null;
    },
    routes: [
      GoRoute(
        name: AppRoute.splash.name,
        path: AppRoute.splash.path,
        pageBuilder:
            (context, state) => NoTransitionPage(child: const SplashPage()),
      ),
      GoRoute(
        name: AppRoute.onboarding.name,
        path: AppRoute.onboarding.path,
        pageBuilder:
            (context, state) => NoTransitionPage(child: const OnboardingPage()),
      ),
      GoRoute(
        name: AppRoute.auth.name,
        path: AppRoute.auth.path,
        pageBuilder:
            (context, state) => NoTransitionPage(child: const AuthPage()),
      ),
      GoRoute(
        name: AppRoute.brandOnboarding.name,
        path: AppRoute.brandOnboarding.path,
        pageBuilder:
            (context, state) =>
                NoTransitionPage(child: const BrandOnboardingPage()),
      ),
      GoRoute(
        name: AppRoute.brandSwitcher.name,
        path: AppRoute.brandSwitcher.path,
        pageBuilder:
            (context, state) =>
                NoTransitionPage(child: const BrandSwitcherPage()),
      ),
      GoRoute(
        name: AppRoute.home.name,
        path: AppRoute.home.path,
        pageBuilder:
            (context, state) => NoTransitionPage(child: const HomePage()),
      ),
      GoRoute(
        name: AppRoute.dashboard.name,
        path: AppRoute.dashboard.path,
        pageBuilder:
            (context, state) => NoTransitionPage(child: const DashboardPage()),
      ),
      GoRoute(
        name: AppRoute.dashboardLocationForm.name,
        path: AppRoute.dashboardLocationForm.path,
        pageBuilder: (context, state) {
          final location =
              state.extra is LocationEntity
                  ? state.extra as LocationEntity
                  : null;
          return NoTransitionPage(
            child: LocationFormPage(location: location),
          );
        },
      ),
      GoRoute(
        name: AppRoute.dashboardServiceForm.name,
        path: AppRoute.dashboardServiceForm.path,
        pageBuilder: (context, state) {
          final service =
              state.extra is ServiceEntity
                  ? state.extra as ServiceEntity
                  : null;
          return NoTransitionPage(
            child: ServiceFormPage(service: service),
          );
        },
      ),
      GoRoute(
        name: AppRoute.dashboardBarberForm.name,
        path: AppRoute.dashboardBarberForm.path,
        pageBuilder: (context, state) {
          final barber =
              state.extra is BarberEntity ? state.extra as BarberEntity : null;
          return NoTransitionPage(
            child: BarberFormPage(barber: barber),
          );
        },
      ),
      GoRoute(
        name: AppRoute.dashboardRewardForm.name,
        path: AppRoute.dashboardRewardForm.path,
        pageBuilder: (context, state) {
          final reward =
              state.extra is RewardEntity ? state.extra as RewardEntity : null;
          return NoTransitionPage(
            child: RewardFormPage(reward: reward),
          );
        },
      ),
      GoRoute(
        name: AppRoute.dashboardRedeemReward.name,
        path: AppRoute.dashboardRedeemReward.path,
        pageBuilder:
            (context, state) =>
                NoTransitionPage(child: const RedeemRewardScanPage()),
      ),
      GoRoute(
        name: AppRoute.booking.name,
        path: AppRoute.booking.path,
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters;
          return NoTransitionPage(
            child: BookingPage(
              initialBarberId: query['barberId'],
              initialServiceId: query['serviceId'],
              initialLocationId: query['locationId'],
            ),
          );
        },
      ),
      GoRoute(
        name: AppRoute.manageBooking.name,
        path: AppRoute.manageBooking.path,
        pageBuilder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId'] ?? '';
          return NoTransitionPage(
            child: ManageBookingPage(appointmentId: appointmentId),
          );
        },
      ),
      GoRoute(
        name: AppRoute.editBooking.name,
        path: AppRoute.editBooking.path,
        pageBuilder: (context, state) {
          final appointmentId = state.pathParameters['appointmentId'] ?? '';
          return NoTransitionPage(
            child: EditBookingPage(appointmentId: appointmentId),
          );
        },
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
