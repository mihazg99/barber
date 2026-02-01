import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
      title: 'Add New Location',
      content: const _AddLocationContent(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomBottomSheet(
      title: 'Add New Location',
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
    final selectedColor = useState<Color>(Colors.grey);

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
              const SnackBar(content: Text('Location added successfully!')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error adding location: $e')),
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
            title: 'Location Name',
            hint: 'e.g., Kitchen, Garage, Office',
            controller: nameController,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a location name';
              }
              return null;
            },
          ),
          Gap(context.appSizes.paddingMedium),
          // Color Field
          CustomTextField.withTitle(
            title: 'Color',
            hint: '#4CAF50',
            controller: colorController,
            onChanged: onColorChanged,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a color';
              }
              if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value!)) {
                return 'Please enter a valid hex color (e.g., #4CAF50)';
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
                border: Border.all(color: Colors.grey[400]!),
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
                  child: Text('Cancel'),
                  color: Colors.grey[600],
                ),
              ),
              Gap(context.appSizes.paddingMedium),
              Expanded(
                child: PrimaryButton.small(
                  onPressed: submitForm,
                  child: Text('Add Location'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
