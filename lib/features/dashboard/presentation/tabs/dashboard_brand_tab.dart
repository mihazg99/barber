import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/dashboard/di.dart';

class DashboardBrandTab extends HookConsumerWidget {
  const DashboardBrandTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(dashboardBrandNotifierProvider.notifier).load();
      });
      return null;
    }, []);

    final state = ref.watch(dashboardBrandNotifierProvider);
    final brandId =
        ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
    final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';

    if (brandId.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.appSizes.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings_outlined,
                size: 64,
                color: context.appColors.captionTextColor,
              ),
              Gap(context.appSizes.paddingMedium),
              Text(
                context.l10n.dashboardBrandSetConfigId,
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

    return switch (state) {
      BaseInitial() || BaseLoading() => const Center(
        child: CircularProgressIndicator(),
      ),
      BaseData(:final data) => _BrandForm(
        brand: data,
        brandId: effectiveBrandId,
      ),
      BaseError(:final message) => Center(
        child: Padding(
          padding: EdgeInsets.all(context.appSizes.paddingLarge),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: context.appTextStyles.medium.copyWith(
              color: context.appColors.errorColor,
            ),
          ),
        ),
      ),
    };
  }
}

class _BrandForm extends HookConsumerWidget {
  const _BrandForm({
    required this.brand,
    required this.brandId,
  });

  final BrandEntity? brand;
  final String brandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = brand != null;
    final nameController = useTextEditingController(text: brand?.name ?? '');
    final primaryColorController = useTextEditingController(
      text: brand?.primaryColor ?? '#000000',
    );
    final logoUrlController = useTextEditingController(
      text: brand?.logoUrl ?? '',
    );
    final contactEmailController = useTextEditingController(
      text: brand?.contactEmail ?? '',
    );
    final slotIntervalController = useTextEditingController(
      text: brand != null ? '${brand!.slotInterval}' : '30',
    );
    final bufferTimeController = useTextEditingController(
      text: brand != null ? '${brand!.bufferTime}' : '5',
    );
    final cancelHoursController = useTextEditingController(
      text: brand != null ? '${brand!.cancelHoursMinimum}' : '48',
    );
    final isMultiLocation = useState(brand?.isMultiLocation ?? false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final notifier = ref.read(dashboardBrandNotifierProvider.notifier);

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;

      // Capture before await - save() triggers setLoading() which unmounts this
      // form, invalidating context.
      final messenger =
          rootScaffoldMessengerKey.currentState ??
          ScaffoldMessenger.maybeOf(context);
      final errorColor = context.appColors.errorColor;
      final primaryColor = context.appColors.primaryColor;
      final savedMsg = context.l10n.dashboardBrandSaved;
      final createdMsg = context.l10n.dashboardBrandCreated;

      final entity = BrandEntity(
        brandId: brandId,
        name: nameController.text.trim(),
        isMultiLocation: isMultiLocation.value,
        primaryColor: primaryColorController.text.trim(),
        logoUrl: logoUrlController.text.trim(),
        contactEmail: contactEmailController.text.trim(),
        slotInterval: int.tryParse(slotIntervalController.text.trim()) ?? 30,
        bufferTime: int.tryParse(bufferTimeController.text.trim()) ?? 5,
        cancelHoursMinimum:
            int.tryParse(cancelHoursController.text.trim()) ?? 48,
      );

      await notifier.save(entity);

      if (messenger != null) {
        final snackBar = notifier.hasError
            ? SnackBar(
                content: Text(notifier.errorMessage ?? 'Error'),
                backgroundColor: errorColor,
              )
            : SnackBar(
                content: Text(isEdit ? savedMsg : createdMsg),
                backgroundColor: primaryColor,
              );
        messenger.showSnackBar(snackBar);
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Brand ID: $brandId',
              style: context.appTextStyles.caption.copyWith(
                color: context.appColors.captionTextColor,
                fontSize: 12,
              ),
            ),
            Gap(context.appSizes.paddingSmall),
            CustomTextField.withTitle(
              title: context.l10n.dashboardBrandName,
              hint: context.l10n.dashboardBrandNameHint,
              controller: nameController,
              validator:
                  (v) =>
                      (v?.trim().isEmpty ?? true)
                          ? context.l10n.dashboardBrandNameRequired
                          : null,
            ),
            Gap(context.appSizes.paddingMedium),
            CustomTextField.withTitle(
              title: context.l10n.dashboardBrandPrimaryColor,
              hint: context.l10n.dashboardBrandPrimaryColorHint,
              controller: primaryColorController,
            ),
            Gap(context.appSizes.paddingMedium),
            CustomTextField.withTitle(
              title: context.l10n.dashboardBrandLogoUrl,
              hint: context.l10n.dashboardBrandLogoUrlHint,
              controller: logoUrlController,
            ),
            Gap(context.appSizes.paddingMedium),
            CustomTextField.withTitle(
              title: context.l10n.dashboardBrandContactEmail,
              hint: context.l10n.dashboardBrandContactEmailHint,
              controller: contactEmailController,
              keyboardType: TextInputType.emailAddress,
            ),
            Gap(context.appSizes.paddingMedium),
            CustomTextField.withTitle(
              title: context.l10n.dashboardBrandSlotInterval,
              hint: '30',
              controller: slotIntervalController,
              keyboardType: TextInputType.number,
            ),
            Gap(context.appSizes.paddingMedium),
            CustomTextField.withTitle(
              title: context.l10n.dashboardBrandBufferTime,
              hint: '5',
              controller: bufferTimeController,
              keyboardType: TextInputType.number,
            ),
            Gap(context.appSizes.paddingMedium),
            CustomTextField.withTitle(
              title: context.l10n.dashboardBrandCancelHours,
              hint: '48',
              controller: cancelHoursController,
              keyboardType: TextInputType.number,
            ),
            Gap(context.appSizes.paddingMedium),
            SwitchListTile(
              title: Text(
                context.l10n.dashboardBrandMultiLocation,
                style: context.appTextStyles.medium.copyWith(
                  color: context.appColors.primaryTextColor,
                ),
              ),
              value: isMultiLocation.value,
              onChanged: (v) => isMultiLocation.value = v,
              activeThumbColor: context.appColors.primaryColor,
            ),
            Gap(context.appSizes.paddingLarge),
            PrimaryButton.big(
              onPressed: submit,
              child: Text(isEdit ? context.l10n.save : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
