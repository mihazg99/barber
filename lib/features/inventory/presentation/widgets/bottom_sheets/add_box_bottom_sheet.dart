import 'package:flutter/material.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_bottom_sheet.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/inventory/domain/entities/box_entity.dart';
import 'package:barber/features/inventory/domain/entities/location_entity.dart';
import 'package:barber/features/inventory/di.dart';

class AddBoxBottomSheet extends HookConsumerWidget {
  const AddBoxBottomSheet({super.key});

  /// Show the add box bottom sheet
  static Future<void> show(BuildContext context) {
    return CustomBottomSheet.show(
      context: context,
      title: context.l10n.addNewBox,
      content: _AddBoxContent(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomBottomSheet(
      title: context.l10n.addNewBox,
      content: _AddBoxContent(),
    );
  }
}

class _AddBoxContent extends HookConsumerWidget {
  _AddBoxContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final selectedLocationId = useState<int?>(null);

    final boxNotifier = ref.read(boxNotifierProvider.notifier);
    final locations = ref.watch(locationNotifierProvider);

    Future<void> submitForm() async {
      if (formKey.currentState?.validate() ?? false) {
        try {
          final box = BoxEntity(
            id: 0,
            label: labelController.text,
            locationId: selectedLocationId.value ?? 0,
          );
          await boxNotifier.insertBox(box);
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.addBoxSuccess)),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.addBoxError('$e'))),
            );
          }
        }
      }
    }

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Box Label Field
          CustomTextField.withTitle(
            title: context.l10n.addBoxLabel,
            hint: context.l10n.addBoxLabelHint,
            controller: labelController,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return context.l10n.addBoxLabelRequired;
              }
              return null;
            },
          ),
          Gap(context.appSizes.paddingMedium),
          // Location Dropdown - Simplified
          Text(
            context.l10n.addItemLocation,
            style: context.appTextStyles.h2.copyWith(
              color: context.appColors.secondaryTextColor,
            ),
          ),
          Gap(context.appSizes.paddingSmall),
          Container(
            padding: EdgeInsets.all(context.appSizes.paddingMedium),
            decoration: BoxDecoration(
              color: context.appColors.secondaryColor,
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
              border: Border.all(color: context.appColors.borderColor),
            ),
            child: Text(
              selectedLocationId.value != null
                  ? 'Location ${selectedLocationId.value} selected'
                  : 'Tap to select location (dropdown will be added later)',
              style: context.appTextStyles.fields,
            ),
          ),
          Gap(context.appSizes.paddingLarge),
          // Buttons
          Row(
            children: [
              Expanded(
                child: PrimaryButton.small(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.cancel),
                  color: context.appColors.captionTextColor,
                ),
              ),
              Gap(context.appSizes.paddingMedium),
              Expanded(
                child: PrimaryButton.small(
                  onPressed: submitForm,
                  child: Text(context.l10n.addNewBox),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
