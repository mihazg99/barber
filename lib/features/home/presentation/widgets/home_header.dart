import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';

/// Professional home header: brand left, notifications right; greeting + date below.
/// Reads brand, logo and user from DI (flavor + home + auth providers).
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeNotifierProvider);
    final flavor = ref.watch(flavorConfigProvider);
    final brandConfig = flavor.values.brandConfig;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    final brandName = homeState is BaseData<HomeData>
        ? (homeState.data.brandName)
        : 'Barber';
    final logoPath = brandConfig.logoPath.isNotEmpty ? brandConfig.logoPath : null;
    final userFirstName = _firstName(currentUser?.fullName);

    final hasLogo = logoPath != null && logoPath.isNotEmpty;
    final greeting =
        userFirstName != null && userFirstName.isNotEmpty
            ? 'Hey, $userFirstName 👋'
            : 'Hey there 👋';
    final date = _formatDate(DateTime.now());

    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.appSizes.paddingMedium,
        context.appSizes.paddingMedium,
        context.appSizes.paddingMedium,
        context.appSizes.paddingSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasLogo)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    logoPath,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderIcon(context),
                  ),
                ),
              if (hasLogo) const Gap(12),
              Expanded(
                child: Text(
                  brandName.toUpperCase(),
                  style: context.appTextStyles.h2.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: context.appColors.primaryTextColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_outlined,
                  color: context.appColors.primaryTextColor,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                ),
              ),
            ],
          ),
          Gap(context.appSizes.paddingMedium),
          Text(
            greeting,
            style: context.appTextStyles.h1.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: context.appColors.primaryTextColor,
              height: 1.2,
            ),
          ),
          Gap(context.appSizes.paddingSmall / 2),
          Text(
            date,
            style: context.appTextStyles.caption.copyWith(
              fontSize: 14,
              color: context.appColors.captionTextColor,
            ),
          ),
        ],
      ),
    );
  }

  static String? _firstName(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return null;
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : null;
  }

  static String _formatDate(DateTime d) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.appColors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.store,
        color: context.appColors.primaryColor,
        size: 22,
      ),
    );
  }
}
