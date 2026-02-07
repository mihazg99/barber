import 'package:flutter/material.dart';

import 'package:barber/features/auth/domain/entities/user_role.dart';
import 'package:barber/gen/l10n/app_localizations.dart';

/// Dashboard tab for barber or superadmin.
class DashboardNavItem {
  const DashboardNavItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

/// Navigation config for dashboard based on role. Labels are localized via [l10n].
abstract final class DashboardNavConfig {
  static List<DashboardNavItem> forRole(UserRole role, AppLocalizations l10n) {
    switch (role) {
      case UserRole.barber:
        return [
          DashboardNavItem(label: l10n.dashboardNavHome, icon: Icons.home_outlined),
          DashboardNavItem(label: l10n.dashboardNavBookings, icon: Icons.calendar_today_outlined),
          DashboardNavItem(label: l10n.dashboardNavShift, icon: Icons.schedule_outlined),
        ];
      case UserRole.superadmin:
        return [
          DashboardNavItem(label: l10n.dashboardNavBrand, icon: Icons.store_outlined),
          DashboardNavItem(label: l10n.dashboardNavLocations, icon: Icons.location_on_outlined),
          DashboardNavItem(label: l10n.dashboardNavServices, icon: Icons.content_cut_outlined),
          DashboardNavItem(label: l10n.dashboardNavRewards, icon: Icons.card_giftcard_outlined),
          DashboardNavItem(label: l10n.dashboardNavBarbers, icon: Icons.person_outline),
          DashboardNavItem(label: l10n.dashboardNavAnalytics, icon: Icons.analytics_outlined),
        ];
      default:
        return [
          DashboardNavItem(label: l10n.dashboardNavHome, icon: Icons.home_outlined),
          DashboardNavItem(label: l10n.dashboardNavBookings, icon: Icons.calendar_today_outlined),
          DashboardNavItem(label: l10n.dashboardNavShift, icon: Icons.schedule_outlined),
        ];
    }
  }
}
