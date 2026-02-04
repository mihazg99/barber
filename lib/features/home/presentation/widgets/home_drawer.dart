import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/home/di.dart';

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
                Navigator.of(context).pop();
                await ref.read(authNotifierProvider.notifier).signOut();
                ref.invalidate(currentUserProvider);
                ref.invalidate(upcomingAppointmentProvider);
                ref.invalidate(homeNotifierProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}
