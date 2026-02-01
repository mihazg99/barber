import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inventory/core/state/base_state.dart';
import 'package:inventory/core/theme/app_colors.dart';
import 'package:inventory/core/theme/app_sizes.dart';
import 'package:inventory/core/theme/app_text_styles.dart';
import 'package:inventory/features/inventory/di.dart';
import 'package:inventory/features/inventory/domain/entities/box_entity.dart';
import 'package:inventory/gen/assets.gen.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BoxListCard extends ConsumerWidget {
  final BoxEntity box;

  const BoxListCard({super.key, required this.box});

  /// Parse color from hex string with fallback
  Color _parseColor(String colorString) {
    try {
      final cleanColor = colorString.replaceAll('#', '');
      if (cleanColor.length == 6) {
        return Color(int.parse('0xFF$cleanColor'));
      }
    } catch (e) {
      // Fallback to purple if parsing fails
    }
    return const Color(0xFF7C5CFA);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get location details for this box
    final locationState = ref.watch(locationNotifierProvider);
    final itemState = ref.watch(itemNotifierProvider);

    final location = switch (locationState) {
      BaseData(:final data) =>
        data.where((loc) => loc.id == box.locationId).firstOrNull,
      _ => null,
    };

    final itemCount = switch (itemState) {
      BaseData(:final data) =>
        data.where((item) => item.boxId == box.id).length,
      _ => 0,
    };

    final chipColor =
        location != null
            ? _parseColor(location.color)
            : const Color(0xFF7C5CFA);
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
              // QR code icon with white outline
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white, width: 1),
                  borderRadius: BorderRadius.circular(
                    context.appSizes.borderRadius,
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    Assets.icons.qr,
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        box.label,
                        style: context.appTextStyles.h2.copyWith(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Gap(4),
                    Row(
                      children: [
                        if (location != null)
                          Chip(
                            label: Text(
                              location.name,
                              style: context.appTextStyles.h2.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            backgroundColor: chipColor,
                            shape: const StadiumBorder(),
                            side: BorderSide.none,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                          ),
                        Gap(context.appSizes.paddingSmall),
                        if (itemCount > 0)
                          Text(
                            itemCount == 1
                                ? '$itemCount item'
                                : '$itemCount items',
                            style: context.appTextStyles.h3.copyWith(
                              color: context.appColors.captionTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
