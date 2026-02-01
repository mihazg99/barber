import 'package:flutter/material.dart';
import 'package:inventory/core/router/app_routes.dart';
import 'package:inventory/gen/assets.gen.dart';
import '../domain/entities/navigation_item.dart';

class NavigationConfig {
  static List<NavigationItem> items = [
    NavigationItem(
      route: AppRoute.home.path,
      label: AppRoute.home.name,
      iconBuilder: (isSelected) => isSelected 
          ? Assets.icons.home
          : Assets.icons.home,
    ),
    NavigationItem(
      route: AppRoute.inventory.path,
      label: AppRoute.inventory.name,
      iconBuilder: (isSelected) => isSelected 
          ? Assets.icons.inventory 
          : Assets.icons.inventory,
    ),
    NavigationItem(
      route: AppRoute.statistics.path,
      label: AppRoute.statistics.name,
      iconBuilder: (isSelected) => isSelected 
          ? Assets.icons.statistics 
          : Assets.icons.statistics ,
    ),
  ];
}
