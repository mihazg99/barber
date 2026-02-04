import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/widgets/custom_back_button.dart';
import 'package:barber/core/widgets/custom_dropdown.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/inventory/di.dart';
import 'package:barber/features/inventory/domain/entities/box_entity.dart';
import 'package:barber/features/inventory/domain/entities/item_entity.dart';
import 'package:barber/features/inventory/domain/entities/location_entity.dart';
import 'package:barber/features/inventory/presentation/widgets/add_item/add_item_photo_picker.dart';

class AddItemPage extends HookConsumerWidget {
  const AddItemPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final titleController = useTextEditingController();
    final categoryController = useTextEditingController();
    final priceController = useTextEditingController();

    final selectedLocation = useState<LocationEntity?>(null);
    final selectedBox = useState<BoxEntity?>(null);
    final isLoading = useState<bool>(false);

    final locations = ref.watch(locationNotifierProvider);
    final boxes = ref.watch(boxNotifierProvider);

    useEffect(() {
      return () {
        titleController.dispose();
        categoryController.dispose();
        priceController.dispose();
      };
    }, []);

    Future<void> save() async {
      if (formKey.currentState!.validate()) {
        isLoading.value = true;
        final item = ItemEntity(
          id: 0,
          name: titleController.value.text,
          quantity: DateTime.now().millisecondsSinceEpoch % 100 + 1,
          boxId: selectedBox.value?.id,
          locationId: selectedLocation.value?.id,
        );

        await ref.read(itemNotifierProvider.notifier).insertItem(item);
        isLoading.value = false;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.addItemSavedSuccess(titleController.text.trim()),
            ),
            backgroundColor: context.appColors.primaryColor,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium,
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Gap(context.appSizes.paddingXxl),
                CustomBackButton.withTitle(context.l10n.addNewItem),
                Gap(context.appSizes.paddingMedium),
                ImagePickerSection(),
                Gap(context.appSizes.paddingMedium),
                CustomTextField.withTitle(
                  title: context.l10n.addItemTitle,
                  hint: context.l10n.addItemTitleHint,
                  controller: titleController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return context.l10n.addItemTitleRequired;
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Handle title changes if needed
                    print('Title: $value');
                  },
                ),
                Gap(context.appSizes.paddingMedium),
                CustomTextField.withTitle(
                  title: context.l10n.addItemCategory,
                  hint: context.l10n.addItemCategoryHint,
                  controller: categoryController,
                  onChanged: (value) {
                    // Handle category changes if needed
                    print('Category: $value');
                  },
                ),
                Gap(context.appSizes.paddingMedium),
                switch (locations) {
                  BaseLoading() => Center(
                    child: CircularProgressIndicator(),
                  ),
                  BaseError(:final message) => Text(
                    context.l10n.addItemError(message),
                    style: TextStyle(color: context.appColors.errorColor),
                  ),
                  BaseData(:final data) => CustomDropdown.withAddNew(
                    items: data.map((location) => location.name).toList(),
                    selectedValue: selectedLocation.value?.name,
                    label: context.l10n.addItemLocation,
                    hint: context.l10n.addItemSelectLocation,
                    onChanged: (value) {
                      final location = data.firstWhereOrNull(
                        (c) => c.name == value,
                      );
                      selectedLocation.value = location;
                      print('Selected location: $value');
                    },
                    onAddNew: () {
                      // Handle add new location
                      print('Add new location tapped');
                      // You can show a dialog or navigate to add location screen
                    },
                  ),
                  _ => SizedBox.shrink(),
                },
                Gap(context.appSizes.paddingMedium),
                switch (boxes) {
                  BaseLoading() => Center(
                    child: CircularProgressIndicator(),
                  ),
                  BaseError(:final message) => Text(
                    context.l10n.addItemError(message),
                    style: TextStyle(color: context.appColors.errorColor),
                  ),
                  BaseData(:final data) => CustomDropdown.withAddNew(
                    items: data.map((box) => box.label).toList(),
                    selectedValue: selectedBox.value?.label,
                    label: context.l10n.addItemBox,
                    hint: context.l10n.addItemSelectBox,
                    onChanged: (value) {
                      final box = data.firstWhereOrNull(
                        (c) => c.label == value,
                      );
                      selectedBox.value = box;
                      print('Selected location: ${box!.id}');
                    },
                    onAddNew: () {
                      // Handle add new location
                      print('Add new box tapped');
                      // You can show a dialog or navigate to add location screen
                    },
                  ),
                  _ => SizedBox.shrink(),
                },
                Gap(context.appSizes.paddingMedium),
                CustomTextField.withTitle(
                  title: context.l10n.addItemPriceOptional,
                  hint: context.l10n.addItemPriceHint,
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    // Handle price changes if needed
                    print('Price: $value');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: context.appSizes.paddingMedium,
          right: context.appSizes.paddingMedium,
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              context.appSizes.paddingMedium,
          top: context.appSizes.paddingSmall,
        ),
        child: PrimaryButton.big(
          onPressed: save,
          loading: isLoading.value,
          child: Text(context.l10n.save),
        ),
      ),
    );
  }
}
