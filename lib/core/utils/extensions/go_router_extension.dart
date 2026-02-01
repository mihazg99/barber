import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:barber/core/navigation/data/navigation_config.dart';

extension GoRouterExtension on BuildContext {
  void navigateToTab(int index) {
    if (index < 0 || index >= NavigationConfig.items.length) return;

    final targetRoute = NavigationConfig.items[index].route;
    final currentLocation = GoRouterState.of(this).uri.toString();
    if (targetRoute != currentLocation) {
      go(targetRoute);
    }
  }

  int get currentNavigationIndex {
    final location = GoRouterState.of(this).uri.toString();
    return NavigationConfig.items
        .indexWhere((item) => item.route == location)
        .clamp(0, NavigationConfig.items.length - 1);
  }

  void navigateToRoute(String routeName) {
    final currentLocation = GoRouterState.of(this).uri.toString();
    if (routeName != currentLocation) {
      go(routeName);
    }
  }

  String get currentNavigationRouteName {
    final location = GoRouterState.of(this).uri.toString();
    return location;
  }
}