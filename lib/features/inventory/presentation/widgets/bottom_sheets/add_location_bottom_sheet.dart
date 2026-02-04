import 'package:flutter/material.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/widgets/custom_bottom_sheet.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/inventory/domain/entities/location_entity.dart';
import 'package:barber/features/inventory/di.dart';

class AddLocationBottomSheet extends HookConsumerWidget {
  const AddLocationBottomSheet({super.key});

  /// Show the add location bottom sheet
  static Future<void> show(BuildContext context) {
    return CustomBottomSheet.show(
      context: context,
      title: context.l10n.addNewLocation,
      content: const _AddLocationContent(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomBottomSheet(
      title: context.l10n.addNewLocation,
      content: const _AddLocationContent(),
    );
  }
}

class _AddLocationContent extends HookConsumerWidget {
  const _AddLocationContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final colorController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final selectedColor = useState<Color>(context.appColors.borderColor);

    final locationNotifier = ref.read(locationNotifierProvider.notifier);

    void onColorChanged(String value) {
      if (value.startsWith('#') && value.length == 7) {
        try {
          final color = Color(int.parse('0xFF${value.substring(1)}'));
          selectedColor.value = color;
        } catch (e) {
          // Invalid color format
        }
      }
    }

    Future<void> submitForm() async {
      if (formKey.currentState?.validate() ?? false) {
        try {
          final location = LocationEntity(
            id: 0,
            name: nameController.text,
            color: colorController.text,
          );
          await locationNotifier.insertLocation(location);
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.addLocationSuccess)),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.addLocationError('$e'))),
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
          // Location Name Field
          CustomTextField.withTitle(
            title: context.l10n.addLocationName,
            hint: context.l10n.addLocationNameHint,
            controller: nameController,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return context.l10n.addLocationNameRequired;
              }
              return null;
            },
          ),
          Gap(context.appSizes.paddingMedium),
          // Color Field
          CustomTextField.withTitle(
            title: context.l10n.addLocationColor,
            hint: context.l10n.addLocationColorHint,
            controller: colorController,
            onChanged: onColorChanged,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return context.l10n.addLocationColorRequired;
              }
              if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value!)) {
                return context.l10n.addLocationColorInvalid;
              }
              return null;
            },
          ),
          // Color preview
          Gap(context.appSizes.paddingSmall),
          Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selectedColor.value,
                shape: BoxShape.circle,
                border: Border.all(color: context.appColors.borderColor),
              ),
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
                  child: Text(context.l10n.addNewLocation),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
