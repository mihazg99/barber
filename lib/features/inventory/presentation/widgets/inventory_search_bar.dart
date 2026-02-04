import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/features/inventory/di.dart';
import 'search_type_toggle.dart';
import 'filter_button.dart';

class InventorySearchBar extends HookConsumerWidget {
  const InventorySearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final searchQuery = useState('');
    final debouncedQuery = useState('');

    final searchNotifier = ref.read(searchNotifierProvider.notifier);
    final searchState = ref.watch(searchNotifierProvider);

    // Determine the current search type
    final currentSearchType = searchNotifier.currentSearchType;
    final isItemsType = currentSearchType == SearchType.items;

    // Clear text controller when search type changes
    useEffect(() {
      controller.clear();
      searchQuery.value = '';
      debouncedQuery.value = '';
      focusNode.unfocus();

      return null;
    }, [searchState]);

    // Debounce searchQuery into debouncedQuery
    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 400), () {
        debouncedQuery.value = searchQuery.value;
      });
      return () => timer.cancel();
    }, [searchQuery.value]);

    // Trigger search when debouncedQuery changes
    useEffect(() {
      Future.microtask(() {
        searchNotifier.setSearchQuery(debouncedQuery.value);
      });
      return null;
    }, [debouncedQuery.value]);

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.appSizes.paddingMedium,
                  ),
                  child: CustomTextField.search(
                    hint: context.l10n.search,
                    enabled: true,
                    onChanged: (val) {
                      searchQuery.value = val;
                    },
                    controller: controller,
                    focusNode: focusNode,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder:
                    (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        child: child,
                      ),
                    ),
                child:
                    isItemsType
                        ? Row(
                          key: const ValueKey('filter'),
                          children: [
                            Gap(context.appSizes.paddingMedium),
                            FilterButton(
                              onTap: () {
                                // Handle filter tap
                              },
                            ),
                            Gap(context.appSizes.paddingMedium),
                          ],
                        )
                        : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ],
          ),
          Gap(context.appSizes.paddingMedium),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.appSizes.paddingMedium,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SearchTypeToggle(
                selectedType: searchNotifier.currentSearchType,
                onTypeChanged: (type) {
                  searchNotifier.setSearchType(type);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
