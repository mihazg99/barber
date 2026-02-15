import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

/// Drawer header showing user info (avatar, name, guest hint).
class HomeDrawerHeader extends StatelessWidget {
  const HomeDrawerHeader({
    super.key,
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
            isGuest ? context.l10n.drawerGuestUser : (userName ?? context.l10n.drawerUser),
            style: context.appTextStyles.bold.copyWith(
              fontSize: 18,
              color: context.appColors.primaryTextColor,
            ),
          ),
          if (isGuest)
            Padding(
              padding: EdgeInsets.only(top: context.appSizes.paddingSmall),
              child: Text(
                context.l10n.drawerSignInToSaveBookings,
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
