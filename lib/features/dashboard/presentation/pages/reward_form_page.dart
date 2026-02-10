import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_back_button.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/rewards/di.dart';
import 'package:barber/features/rewards/domain/entities/reward_entity.dart';

/// Full-page form for add/edit reward. Pass [reward] for edit, null for create.
class RewardFormPage extends HookConsumerWidget {
  const RewardFormPage({super.key, this.reward});

  final RewardEntity? reward;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = reward != null;
    final nameController = useTextEditingController(text: reward?.name ?? '');
    final descriptionController = useTextEditingController(
      text: reward?.description ?? '',
    );
    final pointsController = useTextEditingController(
      text: reward != null ? '${reward!.pointsCost}' : '',
    );
    final sortOrderController = useTextEditingController(
      text: reward != null ? '${reward!.sortOrder}' : '0',
    );
    final isActive = useState(reward?.isActive ?? true);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final effectiveBrandId = ref.watch(dashboardBrandIdProvider);
    final notifier = ref.read(dashboardRewardsNotifierProvider.notifier);

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (effectiveBrandId.isEmpty) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardNoBrand),
            backgroundColor: context.appColors.errorColor,
          ),
        );
        return;
      }

      final points = int.tryParse(pointsController.text.trim());
      final sortOrder = int.tryParse(sortOrderController.text.trim()) ?? 0;
      if (points == null || points < 0) {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(context.l10n.dashboardRewardPointsInvalid),
            backgroundColor: context.appColors.errorColor,
          ),
        );
        return;
      }

      final rewardId =
          isEdit ? reward!.rewardId : _slugFromName(nameController.text.trim());

      final entity = RewardEntity(
        rewardId: rewardId,
        brandId: effectiveBrandId,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        pointsCost: points,
        sortOrder: sortOrder,
        isActive: isActive.value,
      );

      await notifier.save(entity);

      if (!context.mounted) return;
      final messenger =
          rootScaffoldMessengerKey.currentState ??
          ScaffoldMessenger.maybeOf(context);
      if (notifier.hasError) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(notifier.errorMessage ?? 'Error'),
            backgroundColor: context.appColors.errorColor,
          ),
        );
      } else {
        ref.invalidate(rewardsForBrandProvider(effectiveBrandId));
        messenger?.showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? context.l10n.dashboardRewardSaved
                  : context.l10n.dashboardRewardCreated,
            ),
            backgroundColor: context.appColors.primaryColor,
          ),
        );
        Navigator.of(context).pop();
      }
    }

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: AppBar(
        leading: CustomBackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(
          isEdit
              ? context.l10n.dashboardRewardEdit
              : context.l10n.dashboardRewardAdd,
          style: context.appTextStyles.h2.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.appColors.primaryTextColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.appSizes.paddingMedium),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField.withTitle(
                title: context.l10n.dashboardRewardName,
                hint: context.l10n.dashboardRewardNameHint,
                controller: nameController,
                validator:
                    (v) =>
                        (v?.trim().isEmpty ?? true)
                            ? context.l10n.dashboardRewardNameRequired
                            : null,
              ),
              Gap(context.appSizes.paddingMedium),
              CustomTextField.withTitle(
                title: context.l10n.dashboardRewardDescription,
                hint: context.l10n.dashboardRewardDescriptionHint,
                controller: descriptionController,
                maxLines: 3,
              ),
              Gap(context.appSizes.paddingMedium),
              CustomTextField.withTitle(
                title: context.l10n.dashboardRewardPointsCostLabel,
                hint: context.l10n.dashboardRewardPointsCostHint,
                controller: pointsController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 0) {
                    return context.l10n.dashboardRewardPointsInvalid;
                  }
                  return null;
                },
              ),
              Gap(context.appSizes.paddingMedium),
              CustomTextField.withTitle(
                title: context.l10n.dashboardRewardSortOrder,
                hint: context.l10n.dashboardRewardSortOrderHint,
                controller: sortOrderController,
                keyboardType: TextInputType.number,
              ),
              Gap(context.appSizes.paddingMedium),
              SwitchListTile(
                title: Text(
                  context.l10n.dashboardRewardActive,
                  style: context.appTextStyles.medium.copyWith(
                    color: context.appColors.primaryTextColor,
                  ),
                ),
                value: isActive.value,
                onChanged: (v) => isActive.value = v,
                activeTrackColor: context.appColors.primaryColor.withValues(
                  alpha: 0.5,
                ),
                activeThumbColor: context.appColors.primaryColor,
              ),
              Gap(context.appSizes.paddingLarge),
              PrimaryButton.big(
                onPressed: submit,
                child: Text(context.l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _slugFromName(String name) {
    final slug = name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return slug.isNotEmpty
        ? slug
        : 'reward-${DateTime.now().millisecondsSinceEpoch}';
  }
}
