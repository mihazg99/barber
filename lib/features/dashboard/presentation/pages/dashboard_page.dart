import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/user_role.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/brand/presentation/widgets/app_header.dart';
import 'package:barber/features/home/di.dart' as home_di;
import 'package:barber/features/dashboard/presentation/config/dashboard_nav_config.dart';
import 'package:barber/features/home/presentation/widgets/home_drawer.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_analytics_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_barber_home_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_brand_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_barbers_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_calendar_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_locations_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_rewards_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_services_tab.dart';
import 'package:barber/features/dashboard/presentation/tabs/dashboard_shift_tab.dart';

/// Dashboard for barber and superadmin roles. Shown instead of main app home.
class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final lastUser = ref.watch(lastSignedInUserProvider);
    final user = userAsync.valueOrNull ?? lastUser;

    // Use fallback for role so useEffect/useState dependencies are stable
    final role = user?.role ?? UserRole.user;

    final superadminTabIndex = useState(0);

    // Centralized data load: fetch once when dashboard mounts or brand changes.
    useEffect(() {
      // Use a mount check to avoid "ref disposed" errors
      bool mounted = true;

      Future.microtask(() async {
        if (!mounted) return;

        if (role == UserRole.superadmin) {
          // Dashboard providers now auto-watch the correct brandId (from user profile)
          // Just trigger the load.
          await ref.read(dashboardBrandNotifierProvider.notifier).load();

          if (!mounted) return;
          await Future.wait([
            ref.read(dashboardLocationsNotifierProvider.notifier).load(),
            ref.read(dashboardServicesNotifierProvider.notifier).load(),
            ref.read(dashboardRewardsNotifierProvider.notifier).load(),
            ref.read(dashboardBarbersNotifierProvider.notifier).load(),
          ]);
        } else if (role == UserRole.barber) {
          // Force refresh of appointments to ensure we have the latest user/barber ID
          ref.invalidate(barberUpcomingAppointmentsProvider);

          // HomeNotifier layout now auto-detects barber's brandId from user profile.
          // Due to provider caching, if we switched users/brands, we want to ensure we load correct data.
          // Check if we have a brandId to load (avoid loading default if we expect a specific one)
          await ref.read(home_di.homeNotifierProvider.notifier).load();
        }
      });
      return () {
        mounted = false;
      };
    }, [role, user?.brandId]);

    final barberTabIndex = ref.watch(dashboardBarberTabIndexProvider);
    final barberTabNotifier = ref.read(
      dashboardBarberTabIndexProvider.notifier,
    );

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final navItems = DashboardNavConfig.forRole(role, context.l10n);

    final isBarber = role == UserRole.barber;
    final selectedIndex = isBarber ? barberTabIndex : superadminTabIndex.value;
    void onTabTap(int index) {
      if (isBarber) {
        barberTabNotifier.state = index;
      } else {
        superadminTabIndex.value = index;
      }
    }

    final body =
        isBarber
            ? IndexedStack(
              index: selectedIndex,
              children: const [
                DashboardBarberHomeTab(),
                DashboardCalendarTab(),
                DashboardShiftTab(),
              ],
            )
            : IndexedStack(
              index: selectedIndex,
              children: [
                const DashboardBrandTab(),
                const DashboardLocationsTab(),
                const DashboardServicesTab(),
                const DashboardRewardsTab(),
                const DashboardBarbersTab(),
                DashboardAnalyticsTab(isSelected: selectedIndex == 5),
              ],
            );

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      endDrawer: const HomeDrawer(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: context.appColors.navigationBackgroundColor,
        elevation: 12,
        shadowColor: Colors.black26,
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: DashboardPage._buildNavItems(
                navItems,
                selectedIndex,
                onTabTap,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static List<Widget> _buildNavItems(
    List<DashboardNavItem> navItems,
    int selectedIndex,
    void Function(int) onTap,
  ) {
    return List.generate(
      navItems.length,
      (index) => _NavItem(
        item: navItems[index],
        isSelected: selectedIndex == index,
        onTap: () => onTap(index),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 22,
              color:
                  isSelected ? colors.primaryColor : colors.secondaryTextColor,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: context.appTextStyles.medium.copyWith(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected
                        ? colors.primaryColor
                        : colors.secondaryTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
