import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:barber/core/push/push_notification_data.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/settings/notification_settings_notifier.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/home/di.dart';

enum _HomeDrawerTileVariant {
  notifications,
  switchBrand,
  login,
  logout,
}

/// Single drawer tile with named constructors for each action.
class HomeDrawerTile extends HookConsumerWidget {
  const HomeDrawerTile._(this._variant, {Key? key}) : super(key: key);

  final _HomeDrawerTileVariant _variant;

  /// Notifications on/off toggle. Persists to SharedPreferences and syncs FCM token.
  const HomeDrawerTile.notifications({Key? key})
    : this._(_HomeDrawerTileVariant.notifications, key: key);

  /// Navigate to brand switcher.
  const HomeDrawerTile.switchBrand({Key? key})
    : this._(_HomeDrawerTileVariant.switchBrand, key: key);

  /// Open login overlay (guest only).
  const HomeDrawerTile.login({Key? key})
    : this._(_HomeDrawerTileVariant.login, key: key);

  /// Logout with confirmation (authenticated only).
  const HomeDrawerTile.logout({Key? key})
    : this._(_HomeDrawerTileVariant.logout, key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (_variant) {
      case _HomeDrawerTileVariant.notifications:
        return _buildNotificationsTile(context, ref);
      case _HomeDrawerTileVariant.switchBrand:
        return _buildSwitchBrandTile(context, ref);
      case _HomeDrawerTileVariant.login:
        return _buildLoginTile(context, ref);
      case _HomeDrawerTileVariant.logout:
        return _buildLogoutTile(context, ref);
    }
  }

  Widget _buildNotificationsTile(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(notificationSettingsNotifierProvider);
    final prefEnabled =
        settingsState is BaseData<bool> ? settingsState.data : true;
    final isLoading = settingsState is BaseLoading<bool>;

    final pushState = ref.watch(pushNotificationNotifierProvider);
    final pushData =
        pushState is BaseData<PushNotificationData> ? pushState.data : null;
    final authStatus =
        pushData?.authorizationStatus ?? AuthorizationStatus.notDetermined;

    // Enabled only if preference is true AND permission is granted/provisional.
    // If notDetermined (skipped onboarding), it shows as OFF so user can toggle ON to request.
    final bool isActuallyEnabled =
        prefEnabled &&
        (authStatus == AuthorizationStatus.authorized ||
            authStatus == AuthorizationStatus.provisional);

    return ListTile(
      leading: Icon(
        Icons.notifications_outlined,
        color: context.appColors.primaryTextColor,
        size: 24,
      ),
      title: Text(
        context.l10n.settingsNotifications,
        style: context.appTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          color: context.appColors.primaryTextColor,
        ),
      ),
      subtitle: Text(
        context.l10n.settingsNotificationsDescription,
        style: context.appTextStyles.caption.copyWith(
          color: context.appColors.secondaryTextColor,
        ),
      ),
      trailing:
          isLoading
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
              : Switch(
                value: isActuallyEnabled,
                onChanged:
                    (value) => _handleNotificationsToggle(
                      context,
                      ref,
                      value,
                      authStatus,
                    ),
              ),
    );
  }

  Future<void> _handleNotificationsToggle(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
    AuthorizationStatus currentStatus,
  ) async {
    // If user is trying to enable but system permissions are denied, warn them.
    if (enabled && currentStatus == AuthorizationStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.notificationsDisabledInSettings),
          backgroundColor: context.appColors.errorColor,
        ),
      );
      // We can attempt to refresh anyway in case they just changed it
    }

    final notifier = ref.read(notificationSettingsNotifierProvider.notifier);
    await notifier.setEnabled(enabled);

    if (enabled) {
      await ref
          .read(pushNotificationNotifierProvider.notifier)
          .refreshPermissionAndToken();
    }
  }

  Widget _buildSwitchBrandTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        Icons.store_rounded,
        color: context.appColors.primaryTextColor,
        size: 24,
      ),
      title: Text(
        context.l10n.switchBrand,
        style: context.appTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          color: context.appColors.primaryTextColor,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        context.push(AppRoute.brandSwitcher.path);
      },
    );
  }

  Widget _buildLoginTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(
        Icons.login_rounded,
        color: context.appColors.primaryTextColor,
        size: 24,
      ),
      title: Text(
        context.l10n.signIn,
        style: context.appTextStyles.body.copyWith(
          fontWeight: FontWeight.w600,
          color: context.appColors.primaryTextColor,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop();
        ref.read(loginOverlayNotifierProvider.notifier).show();
      },
    );
  }

  Widget _buildLogoutTile(BuildContext context, WidgetRef ref) {
    final isLoggingOut = useState(false);

    return ListTile(
      leading:
          isLoggingOut.value
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _LogoutConfirmDialog(),
    );

    if (confirm != true || !context.mounted) return;

    final container = ProviderScope.containerOf(context);
    isLoggingOut.value = true;

    try {
      container.read(isLoggingOutProvider.notifier).state = true;

      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        final currentLocation = GoRouterState.of(context).uri.path;
        if (currentLocation != AppRoute.home.path) {
          context.go(AppRoute.home.path);
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      container.invalidate(upcomingAppointmentProvider);
      container.invalidate(currentUserProvider);
      container.read(upcomingAppointmentProvider);
      container.read(currentUserProvider);

      // Revoke FCM token before sign-out so the old user stops receiving
      // push notifications on this device.
      await container
          .read(pushNotificationNotifierProvider.notifier)
          .deleteToken();

      await container.read(authNotifierProvider.notifier).signOut();
      container.read(lastSignedInUserProvider.notifier).state = null;
      container.invalidate(homeNotifierProvider);
      container.read(isGuestLoginIntentProvider.notifier).state = false;
      container.read(routerRefreshNotifierProvider).notify();
    } catch (e) {
      debugPrint('[HomeDrawer] Logout error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.logoutFailed(e.toString())),
            backgroundColor: context.appColors.errorColor,
          ),
        );
      }
    } finally {
      container.read(isLoggingOutProvider.notifier).state = false;
      isLoggingOut.value = false;
    }
  }
}

class _LogoutConfirmDialog extends StatelessWidget {
  const _LogoutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.logoutConfirmTitle),
      content: Text(context.l10n.logoutConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.l10n.logout),
        ),
      ],
    );
  }
}
