import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/brand/di.dart' as brand_di;

class HomeDrawer extends ConsumerWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: context.appColors.backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Gap(context.appSizes.paddingLarge),
            ListTile(
              leading: Icon(
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
              onTap: () async {
                final container = ProviderScope.containerOf(context);
                // Set flag FIRST (before pop/signOut) so providers return null streams and cancel listeners
                // immediately—avoids PERMISSION_DENIED spike when auth becomes null.
                container.read(isLoggingOutProvider.notifier).state = true;
                Navigator.of(context).pop();
                container.invalidate(upcomingAppointmentProvider);
                container.invalidate(currentUserProvider);
                container.read(upcomingAppointmentProvider);
                container.read(currentUserProvider);
                // Clear any selected brand override so next login starts fresh
                container
                    .read(brand_di.selectedBrandIdProvider.notifier)
                    .state = null;
                await container.read(authNotifierProvider.notifier).signOut();
                container.read(isLoggingOutProvider.notifier).state = false;
                container.invalidate(lastSignedInUserProvider);
                container.invalidate(homeNotifierProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}
