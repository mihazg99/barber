import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/features/rewards/domain/entities/reward_entity.dart';

/// Superadmin rewards tab. List, add, edit, delete rewards.
class DashboardRewardsTab extends HookConsumerWidget {
  const DashboardRewardsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(dashboardRewardsNotifierProvider.notifier).load();
      });
      return null;
    }, []);

    final state = ref.watch(dashboardRewardsNotifierProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          switch (state) {
            BaseInitial() => const _RewardsShimmer(),
            BaseLoading() => const _RewardsShimmer(),
            BaseData(:final data) => _RewardsList(
              rewards: data,
              onAdd: () => context.push(AppRoute.dashboardRewardForm.path),
              onEdit:
                  (r) => context.push(
                    AppRoute.dashboardRewardForm.path,
                    extra: r,
                  ),
              onDelete: (r) => _confirmDelete(context, ref, r),
            ),
            BaseError(:final message) => _RewardsError(
              message: message,
              onRetry:
                  () =>
                      ref
                          .read(dashboardRewardsNotifierProvider.notifier)
                          .load(),
            ),
          },
          Positioned(
            right: 24,
            bottom: 24,
            child: FloatingActionButton(
              onPressed: () => context.push(AppRoute.dashboardRewardForm.path),
              backgroundColor: context.appColors.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RewardEntity reward,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(context.l10n.dashboardRewardDeleteConfirm),
            content: Text(context.l10n.dashboardRewardDeleteConfirmMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: context.appColors.errorColor,
                ),
                child: Text(context.l10n.dashboardRewardDeleteButton),
              ),
            ],
          ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(dashboardRewardsNotifierProvider.notifier)
          .delete(reward.rewardId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardRewardDeleted),
            backgroundColor: context.appColors.primaryColor,
          ),
        );
      }
    }
  }
}

class _RewardsShimmer extends StatelessWidget {
  const _RewardsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      children: List.generate(
        4,
        (_) => Padding(
          padding: EdgeInsets.only(bottom: context.appSizes.paddingSmall),
          child: ShimmerWrapper(
            variant: ShimmerVariant.dashboard,
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: context.appColors.menuBackgroundColor,
                borderRadius: BorderRadius.circular(
                  context.appSizes.borderRadius,
                ),
              ),
              padding: EdgeInsets.all(context.appSizes.paddingMedium),
              child: Row(
                children: [
                  ShimmerPlaceholder(
                    width: 140,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const Spacer(),
                  ShimmerPlaceholder(
                    width: 48,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardsList extends StatelessWidget {
  const _RewardsList({
    required this.rewards,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<RewardEntity> rewards;
  final VoidCallback onAdd;
  final void Function(RewardEntity) onEdit;
  final void Function(RewardEntity) onDelete;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.appSizes.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                size: 64,
                color: context.appColors.captionTextColor,
              ),
              Gap(context.appSizes.paddingMedium),
              Text(
                context.l10n.dashboardRewardEmpty,
                textAlign: TextAlign.center,
                style: context.appTextStyles.medium.copyWith(
                  color: context.appColors.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return _RewardCard(
          reward: reward,
          onTap: () => onEdit(reward),
          onDelete: () => onDelete(reward),
        );
      },
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.onTap,
    required this.onDelete,
  });

  final RewardEntity reward;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: context.appSizes.paddingSmall),
      color: context.appColors.menuBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        child: Padding(
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reward.name,
                            style: context.appTextStyles.h2.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.appColors.primaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!reward.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.appColors.captionTextColor
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.l10n.dashboardRewardInactive,
                              style: context.appTextStyles.caption.copyWith(
                                fontSize: 11,
                                color: context.appColors.secondaryTextColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (reward.description.isNotEmpty) ...[
                      Gap(4),
                      Text(
                        reward.description,
                        style: context.appTextStyles.caption.copyWith(
                          fontSize: 12,
                          color: context.appColors.captionTextColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    Gap(4),
                    Text(
                      context.l10n.dashboardRewardPointsCost(reward.pointsCost),
                      style: context.appTextStyles.h2.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: context.appColors.errorColor,
                  size: 22,
                ),
                onPressed: onDelete,
                tooltip: context.l10n.dashboardRewardDeleteButton,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardsError extends StatelessWidget {
  const _RewardsError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.appSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: context.appColors.errorColor,
            ),
            Gap(context.appSizes.paddingMedium),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.appTextStyles.medium.copyWith(
                color: context.appColors.secondaryTextColor,
              ),
            ),
            Gap(context.appSizes.paddingMedium),
            PrimaryButton.small(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
