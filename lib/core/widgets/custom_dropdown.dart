import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

class CustomDropdown extends HookWidget {
  final List<String> items;
  final String? selectedValue;
  final String label;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onAddNew;
  final bool includeAddNew;
  final String addNewLabel;
  final String hint;

  const CustomDropdown._({
    required this.items,
    required this.selectedValue,
    required this.label,
    required this.onChanged,
    this.onAddNew,
    required this.includeAddNew,
    this.addNewLabel = 'Add new',
    required this.hint,
    Key? key,
  }) : super(key: key);

  factory CustomDropdown.withAddNew({
    required List<String> items,
    required String? selectedValue,
    required String label,
    required String hint,
    required ValueChanged<String?> onChanged,
    required VoidCallback onAddNew,
    Key? key,
  }) {
    return CustomDropdown._(
      items: items,
      selectedValue: selectedValue,
      label: label,
      onChanged: onChanged,
      onAddNew: onAddNew,
      includeAddNew: true,
      hint: hint,
      key: key,
    );
  }

  factory CustomDropdown.normal({
    required List<String> items,
    required String? selectedValue,
    required String label,
    required ValueChanged<String?> onChanged,
    required String hint,
    Key? key,
  }) {
    return CustomDropdown._(
      items: items,
      selectedValue: selectedValue,
      label: label,
      onChanged: onChanged,
      includeAddNew: false,
      key: key,
      hint: hint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = useState<String?>(selectedValue);
    final dropdownItems = includeAddNew ? [addNewLabel, ...items] : items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: context.appTextStyles.h2.copyWith(
                color: context.appColors.secondaryTextColor,
              ),
            ),
          ),
        DropdownButtonFormField<String>(
          value: selected.value != addNewLabel ? selected.value : null,
          hint: Text(
            hint,
            style: context.appTextStyles.fields.copyWith(
              color: context.appColors.hintTextColor,
            ),
          ),
          isExpanded: true,
          dropdownColor: context.appColors.menuBackgroundColor,
          decoration: InputDecoration(
            fillColor: context.appColors.secondaryColor,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
              borderSide: BorderSide(
                color: context.appColors.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
              borderSide: BorderSide(
                color: context.appColors.primaryColor,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          items:
              dropdownItems.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: context.appTextStyles.h2,
                  ),
                );
              }).toList(),
          onChanged: (value) {
            if (value == addNewLabel && onAddNew != null) {
              selected.value = null;
              onChanged(null);
              onAddNew!();
            } else {
              selected.value = value;
              onChanged(value);
            }
          },
        ),
      ],
    );
  }
}
