import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inventory/core/navigation/presentation/widgets/bottom_nav_bar.dart';
import 'package:inventory/core/theme/app_colors.dart';
import 'package:inventory/core/theme/app_sizes.dart';
import 'package:inventory/core/utils/extensions/safe_padding_extension.dart';
import 'package:inventory/features/home/presentation/widgets/carousel_slider_section.dart';
import 'package:inventory/features/home/presentation/widgets/scan_qr_code_button.dart';
import 'package:inventory/features/inventory/di.dart';
import 'package:inventory/core/state/base_state.dart';
import 'package:inventory/features/inventory/domain/entities/item_entity.dart';
import 'package:inventory/features/home/presentation/widgets/search_dropdown.dart';
import 'package:inventory/features/inventory/domain/entities/box_entity.dart';
import 'package:inventory/features/inventory/domain/entities/location_entity.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final itemState = ref.watch(itemNotifierProvider);

    if (itemState is BaseInitial) {
      Future.microtask(() {
        ref.read(itemNotifierProvider.notifier).getAllItems();
      });
    }

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              Gap(context.safeTopPadding),
              const SearchDropdown(),
              Gap(context.appSizes.paddingMedium),
              ScanQrCodeButton(),
              Gap(context.appSizes.paddingMedium),
              CarouselSliderSection(),
              Gap(context.appSizes.paddingMedium),

              _buildItemsCountCard(context, itemState),

              Gap(context.appSizes.paddingMedium),
              // Use the new SearchDropdown widget
              // Add Item Button
              Consumer(
                builder: (context, ref, _) {
                  return FilledButton(
                    onPressed: () async {
                      final notifier = ref.read(itemNotifierProvider.notifier);
                      // Simulate adding a dummy item (random name/quantity/boxId)
                      final item = ItemEntity(
                        id: 0, // id will be auto-generated
                        name: 'Item 4E6 4E6 4E6',
                        quantity:
                            DateTime.now().millisecondsSinceEpoch % 100 + 1,
                        boxId:
                            1, // You may want to randomize or select a valid boxId
                      );
                      await notifier.insertItem(item);
                      final state = ref.read(itemNotifierProvider);
                      if (state is BaseError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to add item: 6AB ${(state as BaseError).message}',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item added! 389')),
                        );
                      }
                    },
                    child: const Text('Simulate Add Item'),
                  );
                },
              ),
              Gap(context.appSizes.paddingSmall),
              // Add Box Button
              Consumer(
                builder: (context, ref, _) {
                  return FilledButton(
                    onPressed: () async {
                      final notifier = ref.read(boxNotifierProvider.notifier);
                      // Simulate adding a dummy box (random label/locationId)
                      final box = BoxEntity(
                        id: 0, // id will be auto-generated
                        label:
                            'Box ${DateTime.now().millisecondsSinceEpoch % 1000}',
                        locationId:
                            1, // You may want to randomize or select a valid locationId
                      );
                      await notifier.insertBox(box);
                      final state = ref.read(boxNotifierProvider);
                      if (state is BaseError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to add box: ${(state as BaseError).message}',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Box added!')),
                        );
                      }
                    },
                    child: const Text('Simulate Add Box'),
                  );
                },
              ),
              Gap(context.appSizes.paddingSmall),
              // Add Location Button
              Consumer(
                builder: (context, ref, _) {
                  return FilledButton(
                    onPressed: () async {
                      final notifier = ref.read(
                        locationNotifierProvider.notifier,
                      );
                      // Simulate adding a dummy location (random name)
                      final location = LocationEntity(
                        id: 0, // id will be auto-generated
                        color: '#000000',
                        name:
                            'Location ${DateTime.now().millisecondsSinceEpoch % 1000}',
                      );
                      await notifier.insertLocation(location);
                      final state = ref.read(locationNotifierProvider);
                      if (state is BaseError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to add location: ${(state as BaseError).message}',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location added!')),
                        );
                      }
                    },
                    child: const Text('Simulate Add Location'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildItemsCountCard(BuildContext context, BaseState state) {
    return Consumer(
      builder: (context, ref, child) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium,
          ),
          padding: EdgeInsets.all(context.appSizes.paddingMedium),
          decoration: BoxDecoration(
            color: context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.appColors.borderColor),
          ),
          child: switch (state) {
            BaseInitial() => _buildLoadingRow(context),
            BaseLoading() => _buildLoadingRow(context),
            BaseData(:final data) => _buildItemsCountRow(
              context,
              ref,
              data.length,
            ),
            BaseError(:final message) => _buildErrorRow(context, ref, message),
          },
        );
      },
    );
  }

  Widget _buildLoadingRow(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              context.appColors.primaryColor,
            ),
          ),
        ),
        Gap(context.appSizes.paddingSmall),
        Text(
          'Loading items...',
          style: TextStyle(
            color: context.appColors.primaryTextColor,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsCountRow(BuildContext context, WidgetRef ref, int count) {
    return Row(
      children: [
        Icon(
          Icons.inventory_2,
          color: context.appColors.primaryColor,
          size: 24,
        ),
        Gap(context.appSizes.paddingSmall),
        Expanded(
          child: Text(
            'Total Items: $count',
            style: TextStyle(
              color: context.appColors.primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: () => ref.read(itemNotifierProvider.notifier).refresh(),
          icon: Icon(
            Icons.refresh,
            color: context.appColors.secondaryTextColor,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorRow(BuildContext context, WidgetRef ref, String message) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          color: context.appColors.errorColor,
          size: 24,
        ),
        Gap(context.appSizes.paddingSmall),
        Expanded(
          child: Text(
            'Error: $message',
            style: TextStyle(color: context.appColors.errorColor, fontSize: 14),
          ),
        ),
        IconButton(
          onPressed: () => ref.read(itemNotifierProvider.notifier).refresh(),
          icon: Icon(
            Icons.refresh,
            color: context.appColors.secondaryTextColor,
            size: 20,
          ),
        ),
      ],
    );
  }
}
