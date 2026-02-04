import 'package:flutter/material.dart';

import 'package:barber/features/auth/domain/entities/user_role.dart';

/// Dashboard tab for barber or superadmin.
class DashboardNavItem {
  const DashboardNavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

/// Navigation config for dashboard based on role.
abstract final class DashboardNavConfig {
  static List<DashboardNavItem> forRole(UserRole role) {
    switch (role) {
      case UserRole.barber:
        return barberItems;
      case UserRole.superadmin:
        return superadminItems;
      default:
        return barberItems;
    }
  }

  static const List<DashboardNavItem> barberItems = [
    DashboardNavItem(label: 'Home', icon: Icons.home_outlined),
    DashboardNavItem(label: 'Bookings', icon: Icons.calendar_today_outlined),
    DashboardNavItem(label: 'Shift', icon: Icons.schedule_outlined),
  ];

  static const List<DashboardNavItem> superadminItems = [
    DashboardNavItem(label: 'Brand', icon: Icons.store_outlined),
    DashboardNavItem(label: 'Locations', icon: Icons.location_on_outlined),
    DashboardNavItem(label: 'Services', icon: Icons.content_cut_outlined),
    DashboardNavItem(label: 'Barbers', icon: Icons.person_outline),
  ];
}
