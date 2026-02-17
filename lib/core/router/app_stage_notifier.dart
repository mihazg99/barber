import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber/core/router/app_stage.dart';

// Dependencies
import 'package:barber/features/onboarding/di.dart'; // onboardingHasCompletedProvider
import 'package:barber/features/auth/di.dart'; // isAuthenticatedProvider, isGuestProvider, isStaffProvider
import 'package:barber/features/brand/di.dart'; // lockedBrandIdProvider

final appStageProvider =
    AsyncNotifierProvider.autoDispose<AppStageNotifier, AppStage>(
      () => AppStageNotifier(),
    );

class AppStageNotifier extends AutoDisposeAsyncNotifier<AppStage> {
  @override
  FutureOr<AppStage> build() async {
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
    // This blocks transition to MainAppStage until we have the brand data.
    final brandConfig = await ref.watch(selectedBrandProvider.future);

    // If config fails to load but we have an ID, we might still proceed
    // or stay in a loading loop. For now, we assume if it completes (even null),
    // we proceed. If it throws, AsyncNotifier handles the error state.
    if (brandConfig != null) {
      // Check Subscription Status
      if (!brandConfig.isSubscriptionActive) {
        return const BillingLockedStage();
      }
    }

    // If we have a brand, we go to the main app.
    // Determine if staff to allow role-based navigation updates
    final isStaff = ref.watch(isStaffProvider);

    return MainAppStage(isStaff: isStaff);
  }
}
