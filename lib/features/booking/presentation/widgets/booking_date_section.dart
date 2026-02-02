import 'package:flutter/material.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class BookingDateSection extends StatelessWidget {
  const BookingDateSection({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;

  @override
  Widget build(BuildContext context) {
    final dates = _generateDates(14); // Next 14 days

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.appSizes.paddingMedium),
          child: Text(
            'Select Date',
            style: context.appTextStyles.h2.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: context.appColors.primaryTextColor,
            ),
          ),
        ),
        Gap(context.appSizes.paddingSmall),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: context.appSizes.paddingMedium),
            itemCount: dates.length,
            separatorBuilder: (_, __) => Gap(context.appSizes.paddingSmall),
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = selectedDate != null &&
                  date.year == selectedDate!.year &&
                  date.month == selectedDate!.month &&
                  date.day == selectedDate!.day;
              return _DateCard(
                date: date,
                isSelected: isSelected,
                onTap: () => onDateSelected(date),
              );
            },
          ),
        ),
      ],
    );
  }

  List<DateTime> _generateDates(int days) {
    final now = DateTime.now();
    return List.generate(days, (index) {
      return DateTime(now.year, now.month, now.day).add(Duration(days: index));
    });
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weekday = DateFormat('EEE').format(date);
    final day = DateFormat('d').format(date);
    final month = DateFormat('MMM').format(date);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 64,
          height: 76,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? context.appColors.primaryColor
                : context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? context.appColors.primaryColor
                  : context.appColors.borderColor.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                weekday,
                style: context.appTextStyles.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? context.appColors.primaryWhiteColor
                      : context.appColors.captionTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                day,
                style: context.appTextStyles.h1.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? context.appColors.primaryWhiteColor
                      : context.appColors.primaryTextColor,
                ),
              ),
              Text(
                month,
                style: context.appTextStyles.caption.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? context.appColors.primaryWhiteColor.withValues(alpha: 0.8)
                      : context.appColors.captionTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
