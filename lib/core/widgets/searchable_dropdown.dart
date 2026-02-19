import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_textfield.dart';

class SearchableDropdown extends HookWidget {
  final String? selectedValue;
  final List<String> items;
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final Future<void> Function(String) onAddItem;

  const SearchableDropdown({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.label,
    required this.hint,
    required this.onChanged,
    required this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: context.appTextStyles.h2.copyWith(
              color: context.appColors.secondaryTextColor,
            ),
          ),
          SizedBox(height: context.appSizes.paddingSmall),
        ],
        GestureDetector(
          onTap: () => _showSelectionDialog(context),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.appSizes.paddingMedium,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: context.appColors.secondaryColor,
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
              border: Border.all(color: context.appColors.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedValue?.isNotEmpty == true ? selectedValue! : hint,
                  style: context.appTextStyles.fields.copyWith(
                    color:
                        selectedValue?.isNotEmpty == true
                            ? context.appColors.primaryTextColor
                            : context.appColors.hintTextColor,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: context.appColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => _SearchDialog(
            items: items,
            onSelected: onChanged,
            onAddItem: onAddItem,
            hint: hint,
          ),
    );
  }
}

class _SearchDialog extends HookWidget {
  final List<String> items;
  final ValueChanged<String> onSelected;
  final Future<void> Function(String) onAddItem;
  final String hint;

  const _SearchDialog({
    required this.items,
    required this.onSelected,
    required this.onAddItem,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final filteredItems = useState(items);
    final searchQuery = useState('');

    useEffect(() {
      void listener() {
        searchQuery.value = searchController.text;
        final query = searchController.text.toLowerCase();
        if (query.isEmpty) {
          filteredItems.value = items;
        } else {
          filteredItems.value =
              items
                  .where((item) => item.toLowerCase().contains(query))
                  .toList();
        }
      }

      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController, items]);

    return Dialog(
      backgroundColor: context.appColors.menuBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.appSizes.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField.search(
              controller: searchController,
              hint: hint,
              // autofocus: true, // Not exposed in simpler version, but effectively what we want
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount:
                      filteredItems.value.isEmpty &&
                              searchQuery.value.isNotEmpty
                          ? 1
                          : filteredItems.value.length,
                  separatorBuilder:
                      (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (filteredItems.value.isEmpty &&
                        searchQuery.value.isNotEmpty) {
                      final query = searchQuery.value.trim();
                      return ListTile(
                        leading: Icon(
                          Icons.add,
                          color: context.appColors.primaryColor,
                        ),
                        title: Text(
                          'Add "$query"',
                          style: context.appTextStyles.body.copyWith(
                            color: context.appColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () async {
                          Navigator.pop(context); // Close first
                          await onAddItem(query);
                          onSelected(query);
                        },
                      );
                    }

                    final item = filteredItems.value[index];
                    return ListTile(
                      title: Text(
                        item,
                        style: context.appTextStyles.body,
                      ),
                      onTap: () {
                        onSelected(item);
                        Navigator.pop(context);
                      },
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ),
            ),
            if (filteredItems.value.isEmpty && searchQuery.value.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No items found',
                    style: context.appTextStyles.caption.copyWith(
                      color: context.appColors.secondaryTextColor,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
