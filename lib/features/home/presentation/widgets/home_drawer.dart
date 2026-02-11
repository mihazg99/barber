import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/home/di.dart';

class HomeDrawer extends HookConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Drawer(
      backgroundColor: context.appColors.backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerHeader(
              isGuest: isGuest,
              userName: currentUser?.fullName,
            ),
            const Divider(),
            Gap(context.appSizes.paddingSmall),
            // Switch Brand option (for all users)
            _SwitchBrandTile(),
            Gap(context.appSizes.paddingSmall),
            // Login or Logout option
            if (isGuest)
              _LoginTile()
            else
              _LogoutTile(),
          ],
        ),
      ),
    );
  }
}

/// Drawer header showing user info
class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.isGuest,
    this.userName,
  });

  final bool isGuest;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.appSizes.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: context.appColors.primaryColor.withOpacity(0.1),
            child: Icon(
              isGuest ? Icons.person_outline : Icons.person,
              size: 32,
              color: context.appColors.primaryColor,
            ),
          ),
          Gap(context.appSizes.paddingMedium),
          Text(
            isGuest ? 'Guest User' : (userName ?? 'User'),
            style: context.appTextStyles.bold.copyWith(
              fontSize: 18,
              color: context.appColors.primaryTextColor,
            ),
          ),
          if (isGuest)
            Padding(
              padding: EdgeInsets.only(top: context.appSizes.paddingSmall),
              child: Text(
                'Sign in to save your bookings',
                style: context.appTextStyles.caption.copyWith(
                  color: context.appColors.secondaryTextColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Switch Brand tile
class _SwitchBrandTile extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        Icons.store_rounded,
        color: context.appColors.primaryTextColor,
        size: 24,
      ),
      title: Text(
        'Switch Barbershop',
        style: context.appTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          color: context.appColors.primaryTextColor,
        ),
      ),
      onTap: () => _handleSwitchBrand(context, ref),
    );
  }

  void _handleSwitchBrand(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    context.push(AppRoute.brandSwitcher.path);
  }
}

/// Login tile for guest users
class _LoginTile extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        Icons.login_rounded,
        color: context.appColors.primaryTextColor,
        size: 24,
      ),
      title: Text(
        'Login',
        style: context.appTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          color: context.appColors.primaryTextColor,
        ),
      ),
      onTap: () => _handleLogin(context, ref),
    );
  }

  void _handleLogin(BuildContext context, WidgetRef ref) {
    // Set flag to indicate intentional login attempt
    ref.read(isGuestLoginIntentProvider.notifier).state = true;
    Navigator.of(context).pop();
    context.push(AppRoute.auth.path);
  }
}

/// Logout tile for authenticated users
class _LogoutTile extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggingOut = useState(false);

    return ListTile(
      leading: isLoggingOut.value
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  context.appColors.primaryTextColor,
                ),
              ),
            )
          : Icon(
              Icons.logout_rounded,
              color: context.appColors.primaryTextColor,
              size: 24,
            ),
      title: Text(
        context.l10n.logout,
        style: context.appTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          color: context.appColors.primaryTextColor,
        ),
      ),
      enabled: !isLoggingOut.value,
      onTap: () => _handleLogout(context, ref, isLoggingOut),
    );
  }

  Future<void> _handleLogout(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isLoggingOut,
  ) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _LogoutConfirmDialog(),
    );

    if (confirm != true || !context.mounted) return;

    // Capture container reference before async operations
    final container = ProviderScope.containerOf(context);
    isLoggingOut.value = true;

    try {
      // Set logout flag to prevent PERMISSION_DENIED errors
      container.read(isLoggingOutProvider.notifier).state = true;
      
      // Close drawer first
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Navigate to home if not already there to avoid disposal issues with other pages
      if (context.mounted) {
        final currentLocation = GoRouterState.of(context).uri.path;
        if (currentLocation != AppRoute.home.path) {
          context.go(AppRoute.home.path);
          // Give navigation time to complete before logout
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      // Invalidate user-specific providers that depend on auth
      // These will automatically cancel their Firestore listeners
      container.invalidate(upcomingAppointmentProvider);
      container.invalidate(currentUserProvider);
      
      // Trigger re-read to cancel listeners immediately
      container.read(upcomingAppointmentProvider);
      container.read(currentUserProvider);
      
      // Perform Firebase sign out
      await container.read(authNotifierProvider.notifier).signOut();
      
      // Clear all user-specific cached data
      container.read(lastSignedInUserProvider.notifier).state = null;
      
      // Invalidate providers to force reload with guest context
      // homeNotifierProvider will reload with the same brand but as guest
      container.invalidate(homeNotifierProvider);
      
      // userBrandsProvider is autoDispose and will clear automatically
      // currentUserLoyaltyPointsProvider is autoDispose and will clear automatically
      // availableTimeSlotsProvider is autoDispose and will clear automatically
      
      // Keep the locked brand - user stays on the same brand as a guest
      // Keep defaultBrandProvider - brand config should remain cached
      
      // Clear guest login intent flag
      container.read(isGuestLoginIntentProvider.notifier).state = false;
      
      // Trigger router refresh to update UI with guest state
      container.read(routerRefreshNotifierProvider).notify();
      
    } catch (e) {
      debugPrint('[HomeDrawer] Logout error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: context.appColors.errorColor,
          ),
        );
      }
    } finally {
      // Use captured container reference (safe even if widget is disposed)
      container.read(isLoggingOutProvider.notifier).state = false;
      isLoggingOut.value = false;
    }
  }
}

/// Logout confirmation dialog
class _LogoutConfirmDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}
