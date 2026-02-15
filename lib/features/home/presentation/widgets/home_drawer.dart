import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/features/auth/di.dart';

import 'home_drawer_header.dart';
import 'home_drawer_tile.dart';

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
            HomeDrawerHeader(
              isGuest: isGuest,
              userName: currentUser?.fullName,
            ),
            const Divider(),
            Gap(context.appSizes.paddingSmall),
            const HomeDrawerTile.notifications(),
            Gap(context.appSizes.paddingSmall),
            const HomeDrawerTile.switchBrand(),
            Gap(context.appSizes.paddingSmall),
            if (isGuest)
              const HomeDrawerTile.login()
            else
              const HomeDrawerTile.logout(),
          ],
        ),
      ),
    );
  }
}
