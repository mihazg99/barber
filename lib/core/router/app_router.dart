import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:barber/features/home/presentation/pages/home_page.dart';
import 'package:barber/features/inventory/presentation/pages/add_item_page.dart';
import 'package:barber/features/inventory/presentation/pages/inventory_page.dart';
import 'package:barber/features/onboarding/di.dart';
import 'package:barber/features/onboarding/presentation/pages/onboarding_page.dart';

import 'app_routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    redirect: (context, state) {
      final completed = ref.read(onboardingHasCompletedProvider);
      if (!completed && state.uri.path != AppRoute.onboarding.path) {
        return AppRoute.onboarding.path;
      }
      if (completed && state.uri.path == AppRoute.onboarding.path) {
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
        name: AppRoute.home.name,
        path: AppRoute.home.path,
        pageBuilder:
            (context, state) => NoTransitionPage(child: const HomePage()),
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

