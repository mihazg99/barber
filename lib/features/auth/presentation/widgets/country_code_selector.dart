import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/auth/data/country_code.dart';

class CountryCodeSelector extends StatelessWidget {
  const CountryCodeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final CountryCode selected;
  final ValueChanged<CountryCode> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.secondaryColor,
      borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
      child: InkWell(
        onTap: enabled ? () => _showPicker(context) : null,
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium,
            vertical: context.appSizes.paddingSmall,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: context.appColors.borderColor),
            borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selected.flag,
                style: const TextStyle(fontSize: 20),
              ),
              Gap(context.appSizes.paddingSmall),
              Text(
                selected.dialCode,
                style: context.appTextStyles.fields.copyWith(
                  color: context.appColors.primaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: context.appColors.captionTextColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<CountryCode>(
      context: context,
      backgroundColor: context.appColors.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(context.appSizes.borderRadius * 1.5),
        ),
      ),
      builder: (context) => _CountryCodePickerSheet(
        selected: selected,
        onSelected: (country) {
          Navigator.of(context).pop(country);
          onChanged(country);
        },
      ),
    );
  }
}

class _CountryCodePickerSheet extends StatefulWidget {
  const _CountryCodePickerSheet({
    required this.selected,
    required this.onSelected,
  });

  final CountryCode selected;
  final ValueChanged<CountryCode> onSelected;

  @override
  State<_CountryCodePickerSheet> createState() => _CountryCodePickerSheetState();
}

class _CountryCodePickerSheetState extends State<_CountryCodePickerSheet> {
  late List<CountryCode> _filtered;
  final _query = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _filtered = List.from(kCountryCodes);
    _query.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _query.removeListener(_applyFilter);
    _query.dispose();
    super.dispose();
  }

  void _applyFilter() {
    setState(() {
      final q = _query.value.trim().toLowerCase();
      if (q.isEmpty) {
        _filtered = List.from(kCountryCodes);
      } else {
        _filtered = kCountryCodes
            .where(
              (c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.dialCode.contains(q) ||
                  c.isoCode.toLowerCase().contains(q),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Gap(context.appSizes.paddingMedium),
            Text(
              'Select country',
              style: context.appTextStyles.h2.copyWith(
                color: context.appColors.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            Gap(context.appSizes.paddingMedium),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.appSizes.paddingMedium),
              child: TextField(
                onChanged: (v) => _query.value = v,
                decoration: InputDecoration(
                  hintText: 'Search country or code',
                  hintStyle: context.appTextStyles.fields.copyWith(
                    color: context.appColors.hintTextColor,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.appColors.captionTextColor,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: context.appColors.secondaryColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: context.appSizes.paddingSmall,
                    horizontal: context.appSizes.paddingMedium,
                  ),
                ),
                style: context.appTextStyles.fields,
              ),
            ),
            Gap(context.appSizes.paddingSmall),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final country = _filtered[index];
                  final isSelected = country.isoCode == widget.selected.isoCode;
                  return ListTile(
                    leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      country.name,
                      style: context.appTextStyles.body.copyWith(
                        color: context.appColors.primaryTextColor,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                    trailing: Text(
                      country.dialCode,
                      style: context.appTextStyles.body.copyWith(
                        color: context.appColors.captionTextColor,
                      ),
                    ),
                    onTap: () => widget.onSelected(country),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
