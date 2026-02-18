import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber/core/router/app_stage.dart';

// Dependencies
import 'package:barber/features/onboarding/di.dart'; // onboardingHasCompletedProvider
import 'package:barber/features/auth/di.dart'; // isAuthenticatedProvider, isGuestProvider, isStaffProvider
import 'package:barber/features/brand/di.dart'; // lockedBrandIdProvider
import 'package:barber/features/brand/domain/entities/brand_entity.dart';

final appStageProvider =
    NotifierProvider.autoDispose<AppStageNotifier, AppStage>(
      () => AppStageNotifier(),
    );

class AppStageNotifier extends AutoDisposeNotifier<AppStage> {
  @override
  AppStage build() {
    // 1. Watch Onboarding State
    // WEB: Bypass onboarding entirely.
    if (kIsWeb) {
      // Proceed to check auth/brand
    } else {
      final onboardingCompleted = ref.watch(onboardingHasCompletedProvider);
      if (!onboardingCompleted) {
        return const OnboardingStage();
      }
    }

    // 2. Watch Auth & Brand State
    // We watch isAuthenticatedProvider to trigger rebuilds when auth changes.
    ref.watch(isAuthenticatedProvider);

    final lockedBrandId = ref.watch(lockedBrandIdProvider);
    final hasLockedBrand = lockedBrandId != null && lockedBrandId.isNotEmpty;

    // 3. Determine Stage

    if (!hasLockedBrand) {
      if (kIsWeb) {
        return const MainAppStage();
      } // Web guests start at home, but usually caught by router
      return const BrandSelectionStage();
    }

    // CRITICAL: Guard routing until selected brand config is fully loaded.
    // Use synchronous cache check to avoid splash flash if data is already available.

    // a) Check Cache (Sync)
    final cachedBrand = ref.read(lastLockedBrandProvider);

    // b) Watch for updates (Async) - keeps stream alive and updates us on changes
    final brandAsync = ref.watch(selectedBrandProvider);

    // Determine effective brand config
    BrandEntity? brandConfig;

    // Prefer cache if it matches our locked ID (fast path)
    if (cachedBrand != null && cachedBrand.brandId == lockedBrandId) {
      brandConfig = cachedBrand;
    }
    // Otherwise use async value if ready
    else if (brandAsync.hasValue) {
      brandConfig = brandAsync.value;
    }

    // If we have config (fast or slow path), check access
    if (brandConfig != null) {
      // Check Subscription Status
      if (!brandConfig.isSubscriptionActive) {
        return const BillingLockedStage();
      }

      // Ready for Main App
      final isStaff = ref.watch(isStaffProvider);
      return MainAppStage(isStaff: isStaff);
    }

    // If no config yet and loading, show splash (LoadingStage)
    if (brandAsync.isLoading) {
      return const LoadingStage();
    }

    // If we aren't loading and have no brand (e.g. error or empty),
    // fall back to brand selection or handle error.
    // For now, return BrandSelection as safe fallback.
    return const BrandSelectionStage();
  }
}
