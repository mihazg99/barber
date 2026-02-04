import 'package:flutter/material.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/shimmer_placeholder.dart';
import 'package:barber/features/booking/domain/entities/time_slot.dart';
import 'package:gap/gap.dart';

class BookingTimeSection extends StatelessWidget {
  const BookingTimeSection({
    super.key,
    required this.timeSlots,
    required this.selectedTimeSlot,
    required this.onTimeSlotSelected,
    required this.isLoading,
    this.title,
  });

  final List<TimeSlot> timeSlots;
  final String? selectedTimeSlot;
  final void Function(TimeSlot) onTimeSlotSelected;
  final bool isLoading;
  final String? title;

  @override
  Widget build(BuildContext context) {
    // When loading but we have previous slots, show them with a small indicator
    // so layout height is preserved and scroll doesn't jump on date tap.
    if (isLoading && timeSlots.isEmpty) {
      return _LoadingState();
    }

    if (!isLoading && timeSlots.isEmpty) {
      return _EmptyState();
    }

    // Group by time of day
    final morningSlots =
        timeSlots
            .where((s) => getTimePeriod(s.time) == TimePeriod.morning)
            .toList();
    final afternoonSlots =
        timeSlots
            .where((s) => getTimePeriod(s.time) == TimePeriod.afternoon)
            .toList();
    final eveningSlots =
        timeSlots
            .where((s) => getTimePeriod(s.time) == TimePeriod.evening)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title ?? context.l10n.bookingSelectTime,
                  style: context.appTextStyles.h2.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.primaryTextColor,
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.appColors.primaryColor,
                  ),
                ),
            ],
          ),
        ),
        Gap(context.appSizes.paddingSmall),
        if (morningSlots.isNotEmpty) ...[
          _TimeGroupSection(
            title: context.l10n.timeMorning,
            slots: morningSlots,
            selectedTimeSlot: selectedTimeSlot,
            onTimeSlotSelected: onTimeSlotSelected,
          ),
          Gap(context.appSizes.paddingMedium),
        ],
        if (afternoonSlots.isNotEmpty) ...[
          _TimeGroupSection(
            title: context.l10n.timeAfternoon,
            slots: afternoonSlots,
            selectedTimeSlot: selectedTimeSlot,
            onTimeSlotSelected: onTimeSlotSelected,
          ),
          Gap(context.appSizes.paddingMedium),
        ],
        if (eveningSlots.isNotEmpty) ...[
          _TimeGroupSection(
            title: context.l10n.timeEvening,
            slots: eveningSlots,
            selectedTimeSlot: selectedTimeSlot,
            onTimeSlotSelected: onTimeSlotSelected,
          ),
        ],
      ],
    );
  }
}

class _TimeGroupSection extends StatelessWidget {
  const _TimeGroupSection({
    required this.title,
    required this.slots,
    required this.selectedTimeSlot,
    required this.onTimeSlotSelected,
  });

  final String title;
  final List<TimeSlot> slots;
  final String? selectedTimeSlot;
  final void Function(TimeSlot) onTimeSlotSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium,
          ),
          child: Text(
            title,
            style: context.appTextStyles.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.appColors.secondaryTextColor,
            ),
          ),
        ),
        Gap(8),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.appSizes.paddingMedium,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                slots.map((slot) {
                  final isSelected = slot.time == selectedTimeSlot;
                  return _TimeChip(
                    timeSlot: slot,
                    isSelected: isSelected,
                    onTap: () => onTimeSlotSelected(slot),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.timeSlot,
    required this.isSelected,
    required this.onTap,
  });

  final TimeSlot timeSlot;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? context.appColors.primaryColor
                    : context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isSelected
                      ? context.appColors.primaryColor
                      : context.appColors.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            timeSlot.time,
            style: context.appTextStyles.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color:
                  isSelected
                      ? context.appColors.primaryWhiteColor
                      : context.appColors.primaryTextColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.appSizes.paddingMedium),
      child: ShimmerWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerPlaceholder(
              width: 100,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            Gap(context.appSizes.paddingSmall),
            ShimmerPlaceholder(
              width: 80,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            Gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                8,
                (_) => ShimmerPlaceholder(
                  width: 56,
                  height: 36,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Gap(context.appSizes.paddingMedium),
            ShimmerPlaceholder(
              width: 80,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            Gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                6,
                (_) => ShimmerPlaceholder(
                  width: 56,
                  height: 36,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 48,
              color: context.appColors.captionTextColor,
            ),
            Gap(context.appSizes.paddingSmall),
            Text(
              context.l10n.bookingNoAvailableTimes,
              style: context.appTextStyles.h2.copyWith(
                color: context.appColors.secondaryTextColor,
              ),
            ),
            Gap(4),
            Text(
              context.l10n.bookingSelectDifferentDate,
              style: context.appTextStyles.caption.copyWith(
                color: context.appColors.captionTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
