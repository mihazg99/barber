import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';

import 'package:barber/features/auth/di.dart'; // To get user
import 'package:barber/features/brand/di.dart'; // To get brand name

class WebHomeBanner extends ConsumerWidget {
  const WebHomeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get Brand Name
    final brandNameAsync = ref.watch(headerBrandNameProvider);
    final brandName = brandNameAsync.valueOrNull ?? '';

    // 2. Get User Name
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final userName = user?.fullName.split(' ').first ?? 'Guest';

    // 3. Greeting Logic
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = context.l10n.webBannerGreetingMorning;
    } else if (hour < 18) {
      greeting = context.l10n.webBannerGreetingAfternoon;
    } else {
      greeting = context.l10n.webBannerGreetingEvening;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(context.appSizes.paddingLarge),
      margin: EdgeInsets.only(bottom: context.appSizes.paddingLarge),
      decoration: BoxDecoration(
        color: context.appColors.primaryColor,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: context.appColors.primaryColor.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Pattern (Optional, kept simple for now)
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.stars_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & Name
              Text(
                '$greeting, $userName',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gap(context.appSizes.paddingSmall),

              // Welcome Message
              Text(
                context.l10n.webBannerWelcome(brandName),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                ),
              ),
              Gap(context.appSizes.paddingMedium),

              // Loyalty Hook / CTA
              Container(
                padding: EdgeInsets.all(context.appSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    context.appSizes.borderRadius / 2,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.loyalty,
                        color: context.appColors.primaryColor,
                        size: 20,
                      ),
                    ),
                    Gap(context.appSizes.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.webBannerLoyaltyTitle,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            context.l10n.webBannerLoyaltyBody,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
