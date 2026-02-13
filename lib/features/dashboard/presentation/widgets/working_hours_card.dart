import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/value_objects/working_hours.dart';

/// Displays the weekly working hours schedule for a barber.
class WorkingHoursCard extends HookWidget {
  const WorkingHoursCard({
    required this.workingHours,
    this.onEdit,
    super.key,
  });

  final WorkingHoursMap? workingHours;
  final VoidCallback? onEdit;

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sizes = context.appSizes;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with gradient
          Container(
            padding: EdgeInsets.all(sizes.paddingMedium),
            decoration: BoxDecoration(
              color: colors.primaryColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.access_time_filled_rounded,
                        color: colors.primaryColor,
                        size: 20,
                      ),
                    ),
                    Gap(sizes.paddingSmall),
                    Text(
                      l10n.shiftMyWorkingHours,
                      style: context.appTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.primaryTextColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                if (onEdit != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.primaryColor.withOpacity(0.2),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              l10n.shiftEditWorkingHours,
                              style: context.appTextStyles.caption.copyWith(
                                color: colors.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(4),
                            Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: colors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(sizes.paddingMedium),
            child: Column(
              children: [
                if (workingHours == null || workingHours!.isEmpty)
                  _buildEmptyState(context)
                else
                  ...List.generate(7, (index) {
                    final dayKey = _dayKeys[index];
                    final dayHours = workingHours![dayKey];
                    return _DayRow(
                      dayLabel: _getDayLabel(context, index),
                      dayHours: dayHours,
                      isLast: index == 6,
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 48,
            color: colors.secondaryTextColor.withOpacity(0.3),
          ),
          const Gap(16),
          Text(
            context.l10n.shiftNoWorkingHours,
            style: context.appTextStyles.medium.copyWith(
              color: colors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(BuildContext context, int index) {
    // Get localized weekday abbreviation
    // index 0 = Monday (weekday 1), index 6 = Sunday (weekday 7)
    final locale = Localizations.localeOf(context).toString();
    final weekday = index + 1; // Convert 0-6 index to 1-7 weekday
    // Create a date for the specific weekday (using a reference date)
    // We'll use a known Monday as base: 2024-01-01 was a Monday
    final baseDate = DateTime(2024, 1, 1); // Monday
    final targetDate = baseDate.add(Duration(days: weekday - 1));
    final formatted = DateFormat('EEE', locale).format(targetDate);
    // Capitalize first letter
    return formatted.isEmpty ? formatted : formatted[0].toUpperCase() + formatted.substring(1);
  }
}

class _DayRow extends HookWidget {
  const _DayRow({
    required this.dayLabel,
    required this.dayHours,
    required this.isLast,
  });

  final String dayLabel;
  final DayWorkingHours? dayHours;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors; // Assume colors are available
    final sizes = context.appSizes;
    final isClosed = dayHours == null;

    // Check if today matches this row to highlight it
    // Note: DateTime.weekday returns 1 for Mon, 7 for Sun.
    // Our list is 0-indexed starting Mon. So index + 1 == weekday.
    // However, I don't have index here. Let's pass it or calculate it.
    // Actually simplicity first.

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          // Day Label Pill
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color:
                  isClosed
                      ? colors.secondaryTextColor.withOpacity(0.05)
                      : colors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              dayLabel,
              style: context.appTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                color:
                    isClosed ? colors.secondaryTextColor : colors.primaryColor,
              ),
            ),
          ),
          Gap(sizes.paddingMedium),

          // Hours or Closed status
          Expanded(
            child: Row(
              children: [
                if (!isClosed) ...[
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: colors.primaryTextColor.withOpacity(0.5),
                  ),
                  const Gap(8),
                ],
                Text(
                  isClosed
                      ? context.l10n.shiftClosed
                      : '${dayHours!.open} – ${dayHours!.close}',
                  style: context.appTextStyles.medium.copyWith(
                    color:
                        isClosed
                            ? colors.secondaryTextColor.withOpacity(0.5)
                            : colors.primaryTextColor,
                    fontWeight: isClosed ? FontWeight.w500 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Visual indicator dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isClosed
                      ? colors.errorColor.withOpacity(0.2)
                      : colors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
