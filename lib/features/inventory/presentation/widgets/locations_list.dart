import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/features/inventory/di.dart';
import 'package:barber/features/inventory/presentation/widgets/location_list_card.dart';

class LocationsList extends ConsumerWidget {
  const LocationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationNotifierProvider);

    return switch (locationState) {
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
                'No locations found',
                style: TextStyle(color: context.appColors.secondaryTextColor),
              ),
            )
            : ListView.separated(
              padding: EdgeInsets.zero,
              physics: BouncingScrollPhysics(),
              itemCount: data.length,
              itemBuilder: (context, index) {
                return LocationListCard(location: data[index]);
              },
              separatorBuilder: (context, index) => Gap(8),
            ),
      _ => const SizedBox.shrink(),
    };
  }
}
