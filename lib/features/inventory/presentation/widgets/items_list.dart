import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/features/inventory/di.dart';
import 'package:barber/features/inventory/presentation/widgets/item_list_card.dart';

class ItemsList extends ConsumerWidget {
  const ItemsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemState = ref.watch(itemNotifierProvider);

    return switch (itemState) {
      BaseLoading() => const Center(child: CircularProgressIndicator()),
      BaseError(:final message) => Center(
        child: Text(
          'Error: $message',
          style: TextStyle(color: context.appColors.errorColor),
        ),
      ),
      BaseData(:final data) =>
        data.isEmpty
            ? Center(
              child: Text(
                'No items found',
                style: TextStyle(color: context.appColors.secondaryTextColor),
              ),
            )
            : ListView.separated(
              padding: EdgeInsets.zero,
              physics: BouncingScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  onDismissed: (direction) {
                    ref.read(itemNotifierProvider.notifier).deleteItem(item.id);
                  },
                  child: ItemListCard(item: data[index]),
                );
              },
              separatorBuilder: (context, index) => Gap(8),
            ),
      _ => const SizedBox.shrink(),
    };
  }
}
