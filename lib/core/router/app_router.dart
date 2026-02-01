import 'package:go_router/go_router.dart';
import 'package:inventory/features/home/presentation/pages/home_page.dart';
import 'package:inventory/features/inventory/presentation/pages/add_item_page.dart';
import 'package:inventory/features/inventory/presentation/pages/inventory_page.dart';

import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  routes: [
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
