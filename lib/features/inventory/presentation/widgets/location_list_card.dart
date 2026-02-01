import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inventory/core/state/base_state.dart';
import 'package:inventory/core/theme/app_colors.dart';
import 'package:inventory/core/theme/app_sizes.dart';
import 'package:inventory/core/theme/app_text_styles.dart';
import 'package:inventory/features/inventory/di.dart';
import 'package:inventory/features/inventory/domain/entities/location_entity.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class LocationListCard extends ConsumerWidget {
  final LocationEntity location;

  const LocationListCard({
    super.key,
    required this.location,
  });

  /// Parse color from hex string with fallback
  Color _parseColor(String colorString) {
    try {
      final cleanColor = colorString.replaceAll('#', '');
      if (cleanColor.length == 6) {
        return Color(int.parse('0xFF$cleanColor'));
      }
    } catch (e) {
      // Fallback to amber if parsing fails
    }
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percentage = .6;

    // Get box and item counts for this location
    final boxState = ref.watch(boxNotifierProvider);
    final itemState = ref.watch(itemNotifierProvider);

    final boxCount = switch (boxState) {
      BaseData(:final data) =>
        data.where((box) => box.locationId == location.id).length,
      _ => 0,
    };

    final itemCount = switch (itemState) {
      BaseData(:final data) =>
        data.where((item) => item.locationId == location.id).length,
      _ => 0,
    };
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
      child: Ink(
        decoration: BoxDecoration(
          color: context.appColors.secondaryColor,
          borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.appSizes.paddingMedium,
          vertical: context.appSizes.paddingSmall,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 15,
                height: 50,
                decoration: BoxDecoration(
                  color: _parseColor(location.color),
                  borderRadius: BorderRadius.circular(
                    context.appSizes.borderRadius,
                  ),
                ),
              ),
              Gap(context.appSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        location.name,
                        style: context.appTextStyles.h2.copyWith(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Gap(4),
                    Text(
                      '$boxCount ${boxCount == 1 ? 'box' : 'boxes'}・$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                      style: context.appTextStyles.h3.copyWith(
                        color: context.appColors.captionTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              CircularPercentIndicator(
                radius: 20.0,
                lineWidth: 4,
                percent: percentage.clamp(0.0, 100.0),
                center: Text(
                  "${(percentage * 100).toStringAsFixed(0)}%",
                  style: context.appTextStyles.h4,
                ),
                backgroundColor: context.appColors.backgroundColor,
                progressColor: context.appColors.primaryColor,
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
