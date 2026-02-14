import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/deep_link/app_path.dart';
import 'package:barber/core/deep_link/deep_link_di.dart';
import 'package:barber/core/deep_link/deep_link_notifier.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/brand/di.dart';
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
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand_selection/presentation/pages/video_portal_page.dart';
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
    debugPrint(
      '[Router Listener] isAuthenticatedProvider changed: ${next.valueOrNull}',
    );
    if (next.valueOrNull == true) {
      // Clear guest login intent flag on successful authentication
      ref.read(isGuestLoginIntentProvider.notifier).state = false;
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
    debugPrint(
      '[Router Listener] currentUserProvider changed: ${next.valueOrNull?.userId}',
    );
    // Only refresh if NOT in brand selection flow (to avoid interrupting animation)
    if (ref.read(isAuthenticatedProvider).valueOrNull == true &&
        next.valueOrNull != null) {
      ref.invalidate(upcomingAppointmentProvider);
      if (!ref.read(isInBrandSelectionFlowProvider)) {
        Future.microtask(() => refreshNotifier.notify());
      } else {
        debugPrint('[Router Listener] Skipping refresh - brand selection in progress');
      }
    }
  });

  // When repo sets lastSignedInUser (Google/Apple/OTP sign-in), invalidate currentUser so stream emits cache and router can redirect to home (not profile setup).
  ref.listen(lastSignedInUserProvider, (prev, next) {
    debugPrint(
      '[Router Listener] lastSignedInUserProvider changed: ${next?.userId}',
    );
    if (next != null && ref.read(isAuthenticatedProvider).valueOrNull == true) {
      ref.invalidate(currentUserProvider);
      Future.microtask(() => refreshNotifier.notify());
    }
  });

  // Listen for brand state changes to trigger redirects (onboarding/switcher)
  ref.listen(userBrandsProvider, (prev, next) {
    debugPrint(
      '[Router Listener] userBrandsProvider changed: ${next.valueOrNull?.length} brands, isLoading=${next.isLoading}',
    );
    // Only refresh if NOT in brand selection flow (to avoid interrupting animation)
    if (!next.isLoading) {
      if (!ref.read(isInBrandSelectionFlowProvider)) {
        debugPrint('[Router Listener] userBrandsProvider triggering refresh');
        refreshNotifier.notify();
      } else {
        debugPrint('[Router Listener] Skipping refresh - brand selection in progress');
      }
    }
  }, fireImmediately: false);

  ref.listen(lockedBrandIdProvider, (prev, next) {
    debugPrint(
      '[Router Listener] lockedBrandIdProvider changed: $prev -> $next',
    );
    // Only refresh if NOT in brand selection flow (to avoid interrupting animation)
    if (!ref.read(isInBrandSelectionFlowProvider)) {
      refreshNotifier.notify();
    } else {
      debugPrint('[Router Listener] Skipping refresh - brand selection in progress');
    }
  });

  // Clear guest login intent when guest gets a brand (they selected one instead of logging in)
  ref.listen(lockedBrandIdProvider, (prev, next) {
    if (next != null && next.isNotEmpty) {
      final isGuest = ref.read(isGuestProvider);
      if (isGuest) {
        ref.read(isGuestLoginIntentProvider.notifier).state = false;
      }
    }
  });

  // Listen for brand config loading completion to trigger redirect from splash
  // This ensures that when defaultBrandProvider finishes loading (or errors),
  // the router redirect logic runs again and navigates away from splash.
  ref.listen<AsyncValue<BrandEntity?>>(defaultBrandProvider, (prev, next) {
    debugPrint(
      '[Router Listener] defaultBrandProvider changed: isLoading=${next.isLoading}, hasValue=${next.hasValue}, hasError=${next.hasError}',
    );
    // Only refresh if NOT in brand selection flow and NOT loading
    // This triggers redirect logic to re-run when brand config finishes loading
    // The redirect logic will check if we're on splash and navigate accordingly
    if (!next.isLoading && !ref.read(isInBrandSelectionFlowProvider)) {
      debugPrint('[Router Listener] Brand config finished loading, triggering router refresh');
      Future.microtask(() => refreshNotifier.notify());
    }
  });

  final goRouter = GoRouter(
    initialLocation: AppRoute.auth.path,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      // Debug logging
      final timestamp = DateTime.now().millisecondsSinceEpoch % 100000;
      debugPrint('[Router $timestamp] redirect: path=${state.uri.path}');
      // Force splash screen on first run (app startup) when landing on default route,
      // but allow Auth as fallback for future refreshes to avoid splash flash.
      if (_isFirstRun && state.uri.path == AppRoute.auth.path) {
        _isFirstRun = false;
        debugPrint('[Router $timestamp] First run -> redirecting to splash');
        return AppRoute.splash.path;
      }
      // Reset _isFirstRun flag after first redirect is handled
      if (_isFirstRun) {
        _isFirstRun = false;
      }

      // Use container from context so we don't use ref during "dependency changed"
      // (e.g. when refreshNotifier.notify() runs from ref.listen), which would throw.
      final container = ProviderScope.containerOf(context);
      final onboardingCompleted = container.read(
        onboardingHasCompletedProvider,
      );
      final isAuthAsync = container.read(isAuthenticatedProvider);
      final isAuthenticated = isAuthAsync.valueOrNull ?? false;
      final isProfileComplete = container.read(isProfileCompleteProvider);
      final authState = container.read(authNotifierProvider);
      final authData =
          authState is BaseData ? (authState as BaseData).data : null;
      final isInProfileStep =
          authData is AuthFlowData && authData.isProfileInfo;

      final effectiveRole = container.read(effectiveUserRoleProvider);
      final isStaff =
          effectiveRole == EffectiveUserRole.barber ||
          effectiveRole == EffectiveUserRole.superadmin;
      final lockedBrandId = container.read(lockedBrandIdProvider);
      final path = state.uri.path;
      final location = state.uri.toString();

      debugPrint(
        '[Router $timestamp] isAuth=$isAuthenticated, role=$effectiveRole, brand=$lockedBrandId, profileComplete=$isProfileComplete, onboardingDone=$onboardingCompleted',
      );

      // CRITICAL: Never redirect away from portal/switcher during brand selection
      // Check both the path AND the brand selection flow flag
      // (portal can be pushed as modal on top of home, so path might still be /)
      final isInBrandSelectionFlow = container.read(isInBrandSelectionFlowProvider);
      if (path == AppRoute.brandOnboarding.path ||
          path == AppRoute.brandSwitcher.path ||
          isInBrandSelectionFlow) {
        debugPrint(
          '[Router $timestamp] ⛔ BLOCKING REDIRECT - Brand selection in progress (path=$path, flag=$isInBrandSelectionFlow)',
        );
        return null;
      }

      // Splash: stay until we know destination, then redirect
      if (path == AppRoute.splash.path) {
        debugPrint('[Router] At splash');
        if (!onboardingCompleted) {
          debugPrint('[Router] Splash -> onboarding');
          return AppRoute.onboarding.path;
        }

        // Wait for auth state to resolve.
        if (isAuthAsync.isLoading) {
          debugPrint('[Router] Splash -> waiting for auth state');
          return null;
        }

        // Brand + auth resolution:
        final hasLockedBrand =
            lockedBrandId != null && lockedBrandId.isNotEmpty;

        if (hasLockedBrand) {
          // Wait for brand config when a brand is locked, but don't block forever.
          // If brand config fails to load, we still allow navigation (brand ID is locked).
          final brandAsync = container.read(defaultBrandProvider);
          
          // CRITICAL: Wait until brand has completed loading (has value or error).
          // This ensures we don't proceed before the brand is loaded.
          // The splash page watches this provider, which triggers the load, but we need to
          // wait here to ensure the load completes before navigating away.
          if (!brandAsync.hasValue && !brandAsync.hasError) {
            debugPrint(
              '[Router] Splash -> waiting for brand config (isLoading=${brandAsync.isLoading}, hasValue=${brandAsync.hasValue}, hasError=${brandAsync.hasError})',
            );
            return null;
          }
          
          // If brand config has error, log but proceed (brand ID is still locked)
          if (brandAsync.hasError) {
            debugPrint(
              '[Router] Splash -> brand config error, but proceeding (brand ID locked): ${brandAsync.error}',
            );
          } else {
            // Brand loaded successfully - proceed with navigation
            debugPrint(
              '[Router] Splash -> brand config loaded successfully: ${brandAsync.valueOrNull?.name ?? "null"}',
            );
          }
        }

        // Decision tree from Splash once everything is resolved.
        if (!hasLockedBrand) {
          debugPrint('[Router] Splash -> brandOnboarding (no brand)');
          return AppRoute.brandOnboarding.path;
        }

        // If we have a locked brand and onboarding is complete, we should always navigate away.
        if (effectiveRole == EffectiveUserRole.guest) {
          debugPrint('[Router] Splash -> home (guest with brand)');
          return AppRoute.home.path;
        }

        // Brand locked + authenticated → role-based dispatch.
        switch (effectiveRole) {
          case EffectiveUserRole.superadmin:
          case EffectiveUserRole.barber:
            debugPrint('[Router] Splash -> dashboard (staff)');
            return AppRoute.dashboard.path;
          case EffectiveUserRole.user:
            debugPrint('[Router] Splash -> home (user)');
            return AppRoute.home.path;
          case EffectiveUserRole.guest:
            // Already handled above, but included for completeness
            debugPrint('[Router] Splash -> home (guest)');
            return AppRoute.home.path;
        }
      }

      // Firebase auth callback deep link (e.g. after login/verify) – not an app route; send to correct screen.
      if (location.contains('firebaseauth') ||
          location.contains('auth/callback')) {
        debugPrint('[Router] Firebase callback detected');
        if (!onboardingCompleted) return AppRoute.onboarding.path;
        if (isAuthenticated && isProfileComplete) {
          return isStaff ? AppRoute.dashboard.path : AppRoute.home.path;
        }
        return AppRoute.auth.path;
      }
      if (!onboardingCompleted && path != AppRoute.onboarding.path) {
        debugPrint('[Router] Not onboarded -> onboarding');
        return AppRoute.onboarding.path;
      }
      if (onboardingCompleted && path == AppRoute.onboarding.path) {
        debugPrint(
          '[Router] Onboarding complete but at onboarding page -> ${isAuthenticated ? "auth or home" : "auth"}',
        );
        if (isAuthenticated) {
          return isProfileComplete
              ? (isStaff ? AppRoute.dashboard.path : AppRoute.home.path)
              : AppRoute.auth.path;
        }
        return AppRoute.auth.path;
      }
      if (onboardingCompleted &&
          effectiveRole == EffectiveUserRole.guest &&
          path != AppRoute.auth.path &&
          path != AppRoute.brandOnboarding.path &&
          path != AppRoute.brandSwitcher.path) {
        // When onboarding is done but user is a guest (no profile/not fully signed in):
        // - If a brand is locked, send them to client home for that brand.
        // - If no brand is locked, send them to the brand onboarding portal.
        final hasLockedBrand =
            lockedBrandId != null && lockedBrandId.isNotEmpty;

        // If at home but no brand, redirect to brand onboarding
        if (path == AppRoute.home.path && !hasLockedBrand) {
          debugPrint(
            '[Router $timestamp] Guest at home but no brand -> brandOnboarding',
          );
          return AppRoute.brandOnboarding.path;
        }

        // If not at home/booking/loyalty and has brand, allow home
        if (hasLockedBrand &&
            path != AppRoute.home.path &&
            path != AppRoute.booking.path &&
            path != AppRoute.loyalty.path) {
          debugPrint(
            '[Router $timestamp] Guest with brand, redirecting to home',
          );
          return AppRoute.home.path;
        }

        // If no brand and not at brandOnboarding, redirect there
        if (!hasLockedBrand) {
          debugPrint(
            '[Router $timestamp] Guest without brand -> brandOnboarding',
          );
          return AppRoute.brandOnboarding.path;
        }
      }

      // Redirect guests with brands away from auth UNLESS they explicitly want to login
      // (prevents getting stuck on auth after brand onboarding)
      if (effectiveRole == EffectiveUserRole.guest &&
          path == AppRoute.auth.path) {
        final hasLockedBrand =
            lockedBrandId != null && lockedBrandId.isNotEmpty;
        final wantsToLogin = container.read(isGuestLoginIntentProvider);
        if (hasLockedBrand && !wantsToLogin) {
          debugPrint(
            '[Router $timestamp] Guest with brand at auth (no intent) -> home',
          );
          return AppRoute.home.path;
        }
      }

      if (isAuthenticated && path == AppRoute.auth.path) {
        // Stay on auth when profile incomplete or when showing profile step (avoid redirect race).
        if (isInProfileStep || !isProfileComplete) return null;
        // After login from /auth, use effective role + brand context.
        final hasLockedBrand =
            lockedBrandId != null && lockedBrandId.isNotEmpty;
        if (!hasLockedBrand) {
          return AppRoute.brandOnboarding.path;
        }
        switch (effectiveRole) {
          case EffectiveUserRole.superadmin:
          case EffectiveUserRole.barber:
            return AppRoute.dashboard.path;
          case EffectiveUserRole.user:
          case EffectiveUserRole.guest:
            if (container.read(hasPendingBookingDraftProvider)) {
              return AppRoute.booking.path;
            }
            return AppRoute.home.path;
        }
      }

      // Brand container + role-based navigation after onboarding.
      // Only applies when the user is authenticated; guests are handled above.
      if (onboardingCompleted && isAuthenticated) {
        debugPrint(
          '[Router] Authenticated block: effectiveRole=$effectiveRole',
        );
        final hasLockedBrand =
            lockedBrandId != null && lockedBrandId.isNotEmpty;

        // No brand locked → always go to brand onboarding portal, except when already there.
        if (!hasLockedBrand &&
            path != AppRoute.brandOnboarding.path &&
            path != AppRoute.onboarding.path) {
          debugPrint(
            '[Router] No brand locked, redirecting to brandOnboarding',
          );
          return AppRoute.brandOnboarding.path;
        }

        // CRITICAL: Allow authenticated users to stay on portal/switcher pages.
        // When users switch brands, they need to remain on the portal page
        // to see the complete cinematic animation before the portal itself
        // navigates them to home. Don't redirect them away!
        if (path == AppRoute.brandOnboarding.path ||
            path == AppRoute.brandSwitcher.path) {
          debugPrint('[Router] Authenticated user on portal/switcher - allowing access for animation');
          return null;
        }

        if (hasLockedBrand) {
          debugPrint('[Router] Brand locked in authenticated block');
          // Brand locked:
          if (effectiveRole == EffectiveUserRole.guest) {
            // Guest user → client home for that brand (unless already on auth/home).
            debugPrint(
              '[Router] Auth block guest: path=$path, staying if auth/home',
            );
            if (path != AppRoute.auth.path && path != AppRoute.home.path) {
              return AppRoute.home.path;
            }
          } else if (isProfileComplete) {
            // Authenticated + profile complete → enforce dashboard vs home.
            if (isStaff && path == AppRoute.home.path) {
              return AppRoute.dashboard.path;
            }
            if (!isStaff && path == AppRoute.dashboard.path) {
              return AppRoute.home.path;
            }
          }
        }
      }
      debugPrint(
        '[Router $timestamp] End of redirect logic, returning null (allow navigation)',
      );
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
        pageBuilder: (context, state) {
          final openScanner =
              state.uri.queryParameters['openScanner'] == 'true';
          return NoTransitionPage(
            child: VideoPortalPage(initialOpenScanner: openScanner),
          );
        },
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

  // Unified Entry Point: deep links (Universal/App Links + FCM) → single routing stream
  ref.listen<BaseState<DeepLinkState>>(deepLinkNotifierProvider, (prev, next) {
    final path = next is BaseData<DeepLinkState> ? next.data.pendingPath : null;
    if (path == null) return;
    if (path.brandId != null && path.brandId!.isNotEmpty) {
      ref.read(lockedBrandIdProvider.notifier).state = path.brandId;
    }
    goRouter.go(path.location);
    ref.read(deepLinkNotifierProvider.notifier).consumePending();
  });

  return goRouter;
});
