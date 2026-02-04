import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/utils/extensions/safe_padding_extension.dart';
import 'package:barber/features/inventory/di.dart';
import '../widgets/inventory_search_bar.dart';
import '../widgets/list_section.dart';
import '../widgets/inventory_speed_dial.dart';
import 'package:barber/core/state/base_state.dart';
import '../widgets/search_type_toggle.dart';

class InventoryPage extends HookConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(itemNotifierProvider.notifier).getAllItems();
        ref.read(boxNotifierProvider.notifier).getAllBoxes();
        ref.read(locationNotifierProvider.notifier).getAllLocations();
      });
      return null;
    }, []);

    final searchState = ref.watch(searchNotifierProvider);
    final searchType =
        searchState is BaseData<SearchType>
            ? searchState.data
            : SearchType.items;

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Column(
              children: [
                Gap(context.safeTopPadding),
                InventorySearchBar(),
                Gap(context.appSizes.paddingMedium),
                ListSection(searchType: searchType),
              ],
            ),
          ),
          Positioned(
            right: 24,
            bottom: 24,
            child: Material(
              color: Colors.transparent,
              child: InventorySpeedDial(),
            ),
          ),
        ],
      ),
    );
  }
}
