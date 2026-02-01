import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inventory/core/theme/app_colors.dart';
import 'package:inventory/core/theme/app_sizes.dart';
import 'package:inventory/core/theme/app_text_styles.dart';
import 'package:inventory/features/inventory/domain/entities/item_entity.dart';
import 'package:inventory/features/inventory/di.dart';

class ItemListCard extends ConsumerWidget {
  final ItemEntity item;

  const ItemListCard({super.key, required this.item});

  Color _parseColor(String colorString) {
    try {
      // Remove # if present and ensure it's a valid hex color
      final cleanColor = colorString.replaceAll('#', '');
      if (cleanColor.length == 6) {
        return Color(int.parse('0xFF$cleanColor'));
      }
    } catch (e) {
      // Fallback to grey if parsing fails
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationNotifier = ref.watch(locationNotifierProvider.notifier);
    final boxNotifier = ref.watch(boxNotifierProvider.notifier);
    final location =
        item.locationId != null
            ? locationNotifier.getLocationByIdFromData(item.locationId!)
            : null;
    final box =
        item.boxId != null ? boxNotifier.getBoxByIdFromData(item.boxId!) : null;

    Widget imageWidget = Container(
      width: 72,
      color: Colors.grey[800],
      child: const Icon(Icons.image, color: Colors.white54, size: 32),
    );

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
      child: Ink(
        decoration: BoxDecoration(
          color: context.appColors.secondaryColor,
          borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
        ),
        padding: const EdgeInsets.all(8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(
                  context.appSizes.borderRadius,
                ),
                child: imageWidget,
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: context.appTextStyles.h2.copyWith(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Gap(4),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            location?.name ?? 'No Location',
                            style: context.appTextStyles.h2.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          backgroundColor:
                              location != null
                                  ? _parseColor(location.color)
                                  : Colors.grey,
                          shape: const StadiumBorder(),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 0,
                          ),
                        ),
                        if (box != null) ...[
                          Gap(context.appSizes.paddingSmall),
                          Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            box.label,
                            style: context.appTextStyles.h3.copyWith(
                              color: context.appColors.captionTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
