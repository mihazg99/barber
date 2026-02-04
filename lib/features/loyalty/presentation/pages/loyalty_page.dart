import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_app_bar.dart';

/// Placeholder for loyalty / rewards screen.
class LoyaltyPage extends ConsumerWidget {
  const LoyaltyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: CustomAppBar.withTitleAndBackButton(
        context.l10n.loyaltyPageTitle,
        onBack: () => context.go(AppRoute.home.path),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.appSizes.paddingMedium),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard,
                size: 64,
                color: context.appColors.captionTextColor,
              ),
              Gap(context.appSizes.paddingMedium),
              Text(
                context.l10n.loyaltyRewardsComingSoon,
                style: context.appTextStyles.h2.copyWith(
                  color: context.appColors.secondaryTextColor,
                ),
              ),
              Gap(context.appSizes.paddingSmall),
              Text(
                context.l10n.loyaltyEarnPointsDescription,
                style: context.appTextStyles.caption.copyWith(
                  color: context.appColors.captionTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
