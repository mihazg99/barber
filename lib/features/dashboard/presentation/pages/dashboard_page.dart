import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/user_role.dart';
import 'package:barber/features/dashboard/presentation/config/dashboard_nav_config.dart';
import 'package:barber/features/home/presentation/widgets/home_drawer.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_barber_home_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_brand_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_barbers_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_bookings_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_locations_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_services_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_shift_tab.dart';

/// Dashboard for barber and superadmin roles. Shown instead of main app home.
class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final role = user?.role ?? UserRole.user;
    final navItems = DashboardNavConfig.forRole(role);
    final selectedIndex = useState(0);

    final body = role == UserRole.barber
        ? IndexedStack(
            index: selectedIndex.value,
            children: const [
              DashboardBarberHomeTab(),
              DashboardBookingsTab(),
              DashboardShiftTab(),
            ],
          )
        : IndexedStack(
            index: selectedIndex.value,
            children: const [
              DashboardBrandTab(),
              DashboardLocationsTab(),
              DashboardServicesTab(),
              DashboardBarbersTab(),
            ],
          );

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      endDrawer: const HomeDrawer(),
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: context.appTextStyles.bold.copyWith(
            color: context.appColors.primaryTextColor,
          ),
        ),
        backgroundColor: context.appColors.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            icon: Icon(
              Icons.settings_outlined,
              color: context.appColors.primaryTextColor,
              size: 24,
            ),
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: body,
      ),
      bottomNavigationBar: Container(
        color: context.appColors.navigationBackgroundColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                navItems.length,
                (index) => _NavItem(
                  item: navItems[index],
                  isSelected: selectedIndex.value == index,
                  onTap: () => selectedIndex.value = index,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final DashboardNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 24,
              color: isSelected ? colors.primaryColor : colors.secondaryTextColor,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: context.appTextStyles.medium.copyWith(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? colors.primaryColor : colors.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
