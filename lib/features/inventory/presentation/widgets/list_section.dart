import 'package:flutter/material.dart';
import 'package:inventory/core/theme/app_sizes.dart';
import 'package:inventory/features/inventory/presentation/widgets/search_type_toggle.dart';
import 'package:inventory/features/inventory/presentation/widgets/items_list.dart';
import 'package:inventory/features/inventory/presentation/widgets/boxes_list.dart';
import 'package:inventory/features/inventory/presentation/widgets/locations_list.dart';

class ListSection extends StatelessWidget {
  final SearchType searchType;

  const ListSection({
    super.key,
    required this.searchType,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.appSizes.paddingMedium,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: _buildList(),
        ),
      ),
    );
  }

  Widget _buildList() {
    switch (searchType) {
      case SearchType.items:
        return const ItemsList();
      case SearchType.boxes:
        return const BoxesList();
      case SearchType.locations:
        return const LocationsList();
    }
  }
} 