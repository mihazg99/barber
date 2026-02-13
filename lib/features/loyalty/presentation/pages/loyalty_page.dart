import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/utils/snackbar_helper.dart';
import 'package:barber/core/widgets/custom_app_bar.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/loyalty/di.dart';
import 'package:barber/features/rewards/di.dart';
import 'package:barber/features/rewards/domain/entities/reward_entity.dart';
import 'package:barber/features/rewards/domain/entities/redemption_entity.dart';

/// Loyalty / rewards screen: catalog, redeem with points, and my rewards (QR to show at barber).
class LoyaltyPage extends HookConsumerWidget {
  const LoyaltyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandId = ref.watch(lockedBrandIdProvider);
    if (brandId == null) {
      return Scaffold(
        backgroundColor: context.appColors.backgroundColor,
        appBar: CustomAppBar.withTitleAndBackButton(
          context.l10n.loyaltyPageTitle,
          onBack: () => context.go(AppRoute.home.path),
        ),
        body: Center(
          child: Text(
            context.l10n.selectBusinessFirst,
            style: context.appTextStyles.body.copyWith(
              color: context.appColors.secondaryTextColor,
            ),
          ),
        ),
      );
    }
    final rewardsAsync = ref.watch(rewardsForBrandProvider(brandId));
    final currentUser = ref.watch(currentUserStreamProvider).valueOrNull;
    final redemptionsAsync =
        currentUser != null
            ? ref.watch(redemptionsForUserProvider(currentUser.userId))
            : const AsyncValue<List<RedemptionEntity>>.data([]);

    ref.listen(loyaltyNotifierProvider, (prev, next) {
      if (next is BaseData<String?>) {
        showSuccessSnackBar(
          context,
          message: context.l10n.loyaltyRedeemSuccess,
        );
        if (currentUser != null) {
          ref.invalidate(redemptionsForUserProvider(currentUser.userId));
        }
        ref.read(loyaltyNotifierProvider.notifier).setInitial();
      } else if (next is BaseError<String?>) {
        showErrorSnackBar(context, message: next.message);
        ref.read(loyaltyNotifierProvider.notifier).setInitial();
      }
    });

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: context.appColors.backgroundColor,
        appBar: CustomAppBar.withTitleAndBackButton(
          context.l10n.loyaltyPageTitle,
          onBack: () => context.go(AppRoute.home.path),
        ),
        body: rewardsAsync.when(
          data: (rewards) => _GuestLoyaltyContent(rewards: rewards),
          loading: () => const _LoyaltyLoadingBody(),
          error: (_, __) => const _ComingSoonContent(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: CustomAppBar.withTitleAndBackButton(
        context.l10n.loyaltyPageTitle,
        onBack: () => context.go(AppRoute.home.path),
      ),
      body: rewardsAsync.when(
        data: (rewards) {
          if (rewards.isEmpty) {
            return const _ComingSoonContent();
          }
          return ListView(
            padding: EdgeInsets.all(context.appSizes.paddingMedium),
            children: [
              _MyRewardsSection(redemptionsAsync: redemptionsAsync),
              Gap(context.appSizes.paddingLarge),
              Text(
                context.l10n.loyaltyViewRewards,
                style: context.appTextStyles.h3.copyWith(
                  color: context.appColors.primaryTextColor,
                ),
              ),
              Gap(context.appSizes.paddingSmall),
              ...rewards.map(
                (r) => _RewardCard(
                  reward: r,
                  user: currentUser,
                  brandId: brandId,
                  onRedeemed: () {
                    ref.invalidate(
                      redemptionsForUserProvider(currentUser.userId),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const _LoyaltyLoadingBody(),
        error: (_, __) => const _ComingSoonContent(),
      ),
    );
  }
}

class _ComingSoonContent extends StatelessWidget {
  const _ComingSoonContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

class _LoyaltyLoadingBody extends StatelessWidget {
  const _LoyaltyLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _GuestLoyaltyContent extends StatelessWidget {
  const _GuestLoyaltyContent({required this.rewards});

  final List<RewardEntity> rewards;

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    if (rewards.isEmpty) {
      return const _ComingSoonContent();
    }

    return ListView(
      padding: EdgeInsets.all(sizes.paddingMedium),
      children: [
        Container(
          padding: EdgeInsets.all(sizes.paddingMedium),
          decoration: BoxDecoration(
            color: colors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colors.primaryColor,
                size: 24,
              ),
              Gap(sizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign in to earn points',
                      style: textStyles.body.copyWith(
                        color: colors.primaryTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Gap(sizes.paddingSmall),
                    Text(
                      'Create an account to collect loyalty points and redeem rewards.',
                      style: textStyles.caption.copyWith(
                        color: colors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Gap(sizes.paddingLarge),
        Text(
          context.l10n.loyaltyViewRewards,
          style: textStyles.h3.copyWith(
            color: colors.primaryTextColor,
          ),
        ),
        Gap(sizes.paddingSmall),
        ...rewards.map(
          (r) => Opacity(
            opacity: 0.6,
            child: Padding(
              padding: EdgeInsets.only(bottom: sizes.paddingSmall),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(sizes.paddingMedium),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.card_giftcard,
                        color: colors.captionTextColor,
                        size: 28,
                      ),
                      Gap(sizes.paddingSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              style: textStyles.h3.copyWith(
                                color: colors.secondaryTextColor,
                              ),
                            ),
                            if (r.description.isNotEmpty) ...[
                              Gap(sizes.paddingSmall),
                              Text(
                                r.description,
                                style: textStyles.caption.copyWith(
                                  color: colors.captionTextColor,
                                ),
                              ),
                            ],
                            Gap(sizes.paddingSmall),
                            Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 14,
                                  color: colors.captionTextColor,
                                ),
                                Gap(sizes.paddingSmall),
                                Text(
                                  '${r.pointsCost} points',
                                  style: textStyles.caption.copyWith(
                                    color: colors.captionTextColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MyRewardsSection extends StatelessWidget {
  const _MyRewardsSection({required this.redemptionsAsync});

  final AsyncValue<List<RedemptionEntity>> redemptionsAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sizes = context.appSizes;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return redemptionsAsync.when(
      data: (redemptions) {
        if (redemptions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.loyaltyMyRewards,
              style: textStyles.h3.copyWith(color: colors.primaryTextColor),
            ),
            Gap(sizes.paddingSmall),
            ...redemptions.map(
              (r) => Padding(
                padding: EdgeInsets.only(bottom: sizes.paddingSmall),
                child: _RedemptionCard(redemption: r),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  const _RedemptionCard({required this.redemption});

  final RedemptionEntity redemption;

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(sizes.paddingMedium),
        child: Row(
          children: [
            if (redemption.isPending) ...[
              QrImageView(
                data: redemption.redemptionId,
                version: QrVersions.auto,
                size: 72,
                backgroundColor: Colors.white,
              ),
              Gap(sizes.paddingMedium),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    redemption.rewardName,
                    style: textStyles.h3.copyWith(
                      color: colors.primaryTextColor,
                    ),
                  ),
                  Gap(sizes.paddingSmall),
                  Text(
                    redemption.status == RedemptionStatus.pending
                        ? 'Show QR at barber'
                        : context.l10n.alreadyRedeemed,
                    style: textStyles.caption.copyWith(
                      color: colors.captionTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends HookConsumerWidget {
  const _RewardCard({
    required this.reward,
    required this.user,
    required this.brandId,
    required this.onRedeemed,
  });

  final RewardEntity reward;
  final UserEntity? user;
  final String brandId;
  final VoidCallback onRedeemed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRedeeming = useState(false);

    ref.listen(loyaltyNotifierProvider, (prev, next) {
      if (prev is BaseLoading<String?> && next is! BaseLoading<String?>) {
        isRedeeming.value = false;
      }
    });

    // Watch loyalty points from provider
    final loyaltyPointsAsync = ref.watch(currentUserLoyaltyPointsProvider);
    final loyaltyPoints = loyaltyPointsAsync.valueOrNull ?? 0;

    final canRedeem =
        user != null &&
        loyaltyPoints >= reward.pointsCost &&
        !isRedeeming.value;

    void redeem() {
      if (user == null || isRedeeming.value) return;
      if (loyaltyPoints < reward.pointsCost) {
        showErrorSnackBar(
          context,
          message: context.l10n.loyaltyInsufficientPoints,
        );
        return;
      }
      isRedeeming.value = true;
      ref.read(loyaltyNotifierProvider.notifier).redeem(reward, user!);
    }

    return _RewardCardContent(
      reward: reward,
      user: user,
      canRedeem: canRedeem,
      isRedeeming: isRedeeming.value,
      onRedeem: redeem,
    );
  }
}

class _RewardCardContent extends StatelessWidget {
  const _RewardCardContent({
    required this.reward,
    required this.user,
    required this.canRedeem,
    required this.isRedeeming,
    required this.onRedeem,
  });

  final RewardEntity reward;
  final UserEntity? user;
  final bool canRedeem;
  final bool isRedeeming;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final sizes = context.appSizes;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final r = reward;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(sizes.paddingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.card_giftcard,
              color: colors.primaryColor,
              size: 28,
            ),
            Gap(sizes.paddingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: textStyles.h3.copyWith(
                      color: colors.primaryTextColor,
                    ),
                  ),
                  if (r.description.isNotEmpty) ...[
                    Gap(sizes.paddingSmall),
                    Text(
                      r.description,
                      style: textStyles.caption.copyWith(
                        color: colors.captionTextColor,
                      ),
                    ),
                  ],
                  Gap(sizes.paddingSmall),
                  Text(
                    '${r.pointsCost} points',
                    style: textStyles.caption.copyWith(
                      color: colors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user != null) ...[
                    Gap(sizes.paddingSmall),
                    PrimaryButton.small(
                      onPressed: canRedeem ? onRedeem : null,
                      loading: isRedeeming,
                      child: Text(context.l10n.loyaltyRedeem),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
