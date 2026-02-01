import 'package:flutter/material.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';

enum SearchType {
  items,
  boxes,
  locations,
}

class SearchTypeToggle extends StatelessWidget {
  final SearchType selectedType;
  final Function(SearchType) onTypeChanged;

  const SearchTypeToggle({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SearchType>(
      segments: const [
        ButtonSegment<SearchType>(
          value: SearchType.items,
          label: Text('Items'),
        ),
        ButtonSegment<SearchType>(
          value: SearchType.boxes,
          label: Text('Boxes'),
        ),
        ButtonSegment<SearchType>(
          value: SearchType.locations,
          label: Text('Locations'),
        ),
      ],
      selected: {selectedType},
      onSelectionChanged: (Set<SearchType> newSelection) {
        onTypeChanged(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return context.appColors.primaryColor;
            }
            return Colors.transparent;
          },
        ),
        foregroundColor: MaterialStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(MaterialState.selected)) {
              return Colors.white;
            }
            return context.appColors.primaryTextColor;
          },
        ),
        side: MaterialStateProperty.all(
          BorderSide(
            color: context.appColors.borderColor,
            width: 1,
          ),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
          ),
        ),
      ),
      showSelectedIcon: false,
    );
  }
} 