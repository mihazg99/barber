import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/deep_link/app_path.dart';
import 'package:barber/core/deep_link/deep_link_di.dart';
import 'package:barber/core/deep_link/deep_link_notifier.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/booking/presentation/pages/booking_page.dart';
import 'package:barber/features/booking/presentation/pages/web_booking_success_page.dart';
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
import 'package:barber/features/home/presentation/pages/home_page.dart';
import 'package:barber/features/inventory/presentation/pages/add_item_page.dart';
import 'package:barber/features/inventory/presentation/pages/inventory_page.dart';
import 'package:barber/features/loyalty/presentation/pages/loyalty_page.dart';
import 'package:barber/features/onboarding/presentation/pages/onboarding_notification_page.dart';
import 'package:barber/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:barber/features/brand_selection/presentation/pages/video_portal_page.dart';
import 'package:barber/features/brand_selection/presentation/pages/brand_switcher_page.dart';
import 'package:barber/features/auth/presentation/pages/auth_page.dart'; // Kept for consistency
import 'package:barber/features/splash/presentation/pages/splash_page.dart';
import 'package:barber/core/presentation/pages/site_not_found_page.dart';
import 'package:barber/core/presentation/pages/subscription_locked_page.dart';

import 'package:barber/core/router/app_stage.dart';
import 'package:barber/core/router/app_stage_notifier.dart';
import 'app_routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Initialize persistence listener for selected brand override
  initSelectedBrandPersistence(ref);

  // Restore Side Effects Handling
  // ===========================================================================

  // 1. Auth State Changes -> Invalidate User Cache
  ref.listen(isAuthenticatedProvider, (prev, next) {
    if (next.valueOrNull == true) {
      // Clear guest login intent flag on successful authentication
      ref.read(isGuestLoginIntentProvider.notifier).state = false;
      ref.invalidate(currentUserProvider);
      ref.invalidate(upcomingAppointmentProvider);
      // We don't need to manually trigger refresh here as AppStageNotifier watches auth state
      // and will trigger router refresh automatically via appStageProvider.
    }
  });

  // 2. User Loaded -> Invalidate Appointment Cache (ensure fresh data)
  ref.listen(currentUserProvider, (prev, next) {
    if (next.valueOrNull != null) {
      ref.invalidate(upcomingAppointmentProvider);
      // Any other user-dependent invalidations
    }
  });

  // 3. Last Signed In User -> Invalidate Current User (Switching accounts?)
  ref.listen(lastSignedInUserProvider, (prev, next) {
    if (next != null && ref.read(isAuthenticatedProvider).valueOrNull == true) {
      ref.invalidate(currentUserProvider);
    }
  });

  // 4. Guest Login Intent Cleanup
  ref.listen(lockedBrandIdProvider, (prev, next) {
    if (next != null && next.isNotEmpty) {
      final isGuest = ref.read(isGuestProvider);
      if (isGuest) {
        ref.read(isGuestLoginIntentProvider.notifier).state = false;
      }
    }
  });

  // ===========================================================================

  final appStageAsync = ref.watch(appStageProvider);

  final goRouter = GoRouter(
    initialLocation: AppRoute.splash.path,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: _RiverpodListenable(ref, appStageProvider),
    redirect: (context, state) {
      // 1. Loading Handling
      if (appStageAsync.isLoading || appStageAsync.hasError) {
        // Allow web booking (brand tag) bypass to preserve URL
        // Explicitly check if path is NOT root, to allow resolution
        if (state.uri.path != '/' && _isPotentialBrandTag(state.uri.path)) {
          return null;
        }

        if (state.uri.path == AppRoute.splash.path) return null;
        return AppRoute.splash.path;
      }

      final stage = appStageAsync.valueOrNull;
      if (stage == null) return AppRoute.splash.path;

      final path = state.uri.path;

      // 2. State-Driven Redirects
      // WEB: Strict Routing
      if (kIsWeb) {
        // Always allow brand tag resolution
        if (_isPotentialBrandTag(path)) return null;

        // Allow success page
        if (state.uri.path == AppRoute.webBookingSuccess.path) return null;

        // Allow Home
        if (path == AppRoute.home.path) return null;

        // Allow Site Not Found explicitly if needed, but matched above or below?
        // Actually, siteNotFound is '/' which matches path.
        // Allow Site Not Found explicitly if needed
        if (path == AppRoute.siteNotFound.path) return null;

        // Block Onboarding, Notification, App Auth (use overlay)
        if (path.startsWith(AppRoute.onboarding.path) ||
            path == AppRoute.auth.path) {
          // If accessing auth directly, redirect to home if locked brand exists
          // Otherwise, if we have a locked brand, go home.
          // If no locked brand, and path is strictly auth, we can't do much on web entry without context.
          final lockedBrandId = ref.read(lockedBrandIdProvider);
          if (lockedBrandId != null) {
            return AppRoute.home.path;
          }
          // If no brand, maybe fall through or let it show auth?
          // But user wants "Site Not Found" for root. Auth is not root.
          // Let's redirect to SiteNotFound if no context.
          return AppRoute.siteNotFound.path;
        }

        // Allow Booking & Sub-routes
        if (path.startsWith(AppRoute.booking.path)) return null;

        // Default fallback for Web
        // Only redirect to SiteNotFound if we genuinely have nowhere else to go
        // AND we are not on a potential brand tag path.
        if (_isPotentialBrandTag(path)) return null;

        return AppRoute.siteNotFound.path;
      }

      switch (stage) {
        case OnboardingStage():
          // Allow web booking (brand tag) bypass
          if (_isPotentialBrandTag(path)) return null;

          if (path == AppRoute.onboarding.path ||
              path == AppRoute.onboardingNotifications.path) {
            return null;
          }
          return AppRoute.onboarding.path;

        case BrandSelectionStage():
          // Allow web booking (brand tag) bypass
          if (_isPotentialBrandTag(path)) return null;

          if (path == AppRoute.brandOnboarding.path ||
              path == AppRoute.brandSwitcher.path) {
            return null;
          }
          return AppRoute.brandOnboarding.path;

        case MainAppStage(isStaff: final isStaff):
          // Role Check
          // (isStaff passed from stage matches ref.read(isStaffProvider) at calculation time)
          // We can also double check ref.read(isStaffProvider) here if we want current sync value,
          // but strict state-driven prefers using the 'stage' properties.

          final defaultPath =
              isStaff ? AppRoute.dashboard.path : AppRoute.home.path;

          // Prevent Guest/User from accessing Dashboard
          if (!isStaff && path.startsWith(AppRoute.dashboard.path)) {
            return AppRoute.home.path;
          }

          // Prevent Staff from accessing Home (Strict Mode)
          if (isStaff && path == AppRoute.home.path) {
            return AppRoute.dashboard.path;
          }

          // Blocking Routes (Auth, Onboarding, BrandPortal if they shouldn't be valid anymore)
          if (path == AppRoute.onboarding.path ||
              path == AppRoute.splash.path ||
              path == AppRoute.auth.path) {
            return defaultPath;
          }

          // Allow Brand Portal for switching brands
          if (path == AppRoute.brandOnboarding.path ||
              path == AppRoute.brandSwitcher.path) {
            return null;
          }

          // Allow all other routes (Booking, Loyalty, Inventory, etc.)
          return null;

        case BillingLockedStage():
          return AppRoute.subscriptionLocked.path;
      }
    },
    routes: [
      GoRoute(
        name: AppRoute.splash.name,
        path: AppRoute.splash.path,
        pageBuilder:
            (context, state) => NoTransitionPage(child: const SplashPage()),
      ),
      GoRoute(
        name: AppRoute.subscriptionLocked.name,
        path: AppRoute.subscriptionLocked.path,
        pageBuilder:
            (context, state) =>
                NoTransitionPage(child: const SubscriptionLockedPage()),
      ),
      GoRoute(
        name: AppRoute.onboarding.name,
        path: AppRoute.onboarding.path,
        pageBuilder:
            (context, state) => NoTransitionPage(child: const OnboardingPage()),
      ),
      GoRoute(
        name: AppRoute.onboardingNotifications.name,
        path: AppRoute.onboardingNotifications.path,
        pageBuilder:
            (context, state) =>
                NoTransitionPage(child: const OnboardingNotificationPage()),
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

      // Main App Routes
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
          return NoTransitionPage(child: LocationFormPage(location: location));
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
          return NoTransitionPage(child: ServiceFormPage(service: service));
        },
      ),
      GoRoute(
        name: AppRoute.dashboardBarberForm.name,
        path: AppRoute.dashboardBarberForm.path,
        pageBuilder: (context, state) {
          final barber =
              state.extra is BarberEntity ? state.extra as BarberEntity : null;
          return NoTransitionPage(child: BarberFormPage(barber: barber));
        },
      ),
      GoRoute(
        name: AppRoute.dashboardRewardForm.name,
        path: AppRoute.dashboardRewardForm.path,
        pageBuilder: (context, state) {
          final reward =
              state.extra is RewardEntity ? state.extra as RewardEntity : null;
          return NoTransitionPage(child: RewardFormPage(reward: reward));
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
      // Site Not Found (Root) - Moved to near end to ensure specific routes match first
      GoRoute(
        name: AppRoute.siteNotFound.name,
        path: AppRoute.siteNotFound.path,
        pageBuilder:
            (context, state) =>
                NoTransitionPage(child: const SiteNotFoundPage()),
      ),
      // Web Booking Route (Catch-all for brand tags)
      GoRoute(
        name: AppRoute.webBooking.name,
        path: AppRoute.webBooking.path,
        pageBuilder: (context, state) {
          // This buffer page handles the async resolution of brand tag -> brandId
          final brandTag = state.pathParameters['brandTag'] ?? '';
          return NoTransitionPage(
            child: _WebBookingResolverPage(brandTag: brandTag),
          );
        },
      ),
      GoRoute(
        name: AppRoute.webBookingSuccess.name,
        path: AppRoute.webBookingSuccess.path,
        pageBuilder:
            (context, state) =>
                NoTransitionPage(child: const WebBookingSuccessPage()),
      ),
    ],
  );

  // Unified Entry Point: deep links
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

class _RiverpodListenable extends ChangeNotifier {
  _RiverpodListenable(this.ref, this.provider) {
    _subscription = ref.listen(provider, (_, __) => notifyListeners());
  }

  final Ref ref;
  final ProviderListenable provider;
  late final ProviderSubscription _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

class _WebBookingResolverPage extends ConsumerStatefulWidget {
  const _WebBookingResolverPage({required this.brandTag});

  final String brandTag;

  @override
  ConsumerState<_WebBookingResolverPage> createState() =>
      _WebBookingResolverPageState();
}

class _WebBookingResolverPageState
    extends ConsumerState<_WebBookingResolverPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveBrand());
  }

  Future<void> _resolveBrand() async {
    // 1. Check if we already have the correct brand loaded
    // final currentBrandId = ref.read(lockedBrandIdProvider);
    // If we implemented a way to store "lockedBrandTag", we could check that too.
    // For now, we always fetch to be safe and ensure validity.

    // 2. Resolve Tag -> ID
    final result = await ref
        .read(brandRepositoryProvider)
        .getByTag(widget.brandTag);

    if (!mounted) return;

    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Error loading brand: ${failure.message}';
        });
      },
      (brand) {
        if (!mounted) return;
        if (brand == null) {
          setState(() {
            _errorMessage = 'Brand not found for tag: ${widget.brandTag}';
          });
        } else {
          // 3. Set Brand ID
          ref.read(lockedBrandIdProvider.notifier).state = brand.brandId;

          // 4. Render Booking Page
          setState(() {
            _resolved = true;
          });
        }
      },
    );
  }

  bool _resolved = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    if (_resolved) {
      // 5. Show Booking Page
      return const HomePage();
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Show loading while resolving
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

bool _isPotentialBrandTag(String path) {
  if (path == '/' || path.isEmpty) return false;

  final reservedPrefixes = [
    '/splash',
    '/onboarding',
    '/auth',
    '/home',
    '/brand_', // brand_onboarding, brand_switcher
    '/dashboard',
    '/booking',
    '/manage_booking',
    '/edit_booking',
    '/loyalty',
    '/inventory',
    '/statistics',
    '/add_new_item',
  ];

  for (final prefix in reservedPrefixes) {
    if (path.startsWith(prefix)) return false;
  }

  return true;
}
