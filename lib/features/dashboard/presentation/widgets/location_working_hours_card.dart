import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/value_objects/working_hours.dart';

/// Displays location working hours in a card format with optional edit button.
class LocationWorkingHoursCard extends StatelessWidget {
  const LocationWorkingHoursCard({
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

    final hasHours =
        workingHours != null &&
        workingHours!.values.any((hours) => hours != null);

    return Container(
      decoration: BoxDecoration(
        color: colors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(sizes.paddingMedium),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.access_time_filled_rounded,
                        color: colors.primaryColor,
                        size: 18,
                      ),
                    ),
                    Gap(sizes.paddingSmall),
                    Text(
                      l10n.dashboardLocationWorkingHours,
                      style: context.appTextStyles.h3.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.primaryTextColor,
                      ),
                    ),
                  ],
                ),
                if (onEdit != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onEdit,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.primaryColor.withValues(alpha: 0.2),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              hasHours ? l10n.edit : l10n.add,
                              style: context.appTextStyles.caption.copyWith(
                                color: colors.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const Gap(4),
                            Icon(
                              hasHours ? Icons.edit_rounded : Icons.add_rounded,
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
          if (!hasHours)
            _buildEmptyState(context)
          else
            Padding(
              padding: EdgeInsets.fromLTRB(
                sizes.paddingMedium,
                0,
                sizes.paddingMedium,
                sizes.paddingMedium,
              ),
              child: Column(
                children: List.generate(7, (index) {
                  final dayKey = _dayKeys[index];
                  final dayHours = workingHours![dayKey];
                  return _DayRow(
                    dayLabel: _getDayLabel(context, index),
                    dayHours: dayHours,
                    isLast: index == 6,
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 40,
            color: colors.secondaryTextColor.withValues(alpha: 0.3),
          ),
          const Gap(12),
          Text(
            context.l10n.dashboardLocationNoWorkingHours,
            textAlign: TextAlign.center,
            style: context.appTextStyles.medium.copyWith(
              color: colors.secondaryTextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(BuildContext context, int index) {
    final locale = Localizations.localeOf(context).toString();
    final weekday = index + 1;
    final baseDate = DateTime(2024, 1, 1); // Monday
    final targetDate = baseDate.add(Duration(days: weekday - 1));
    final formatted = DateFormat('EEE', locale).format(targetDate);
    return formatted.isEmpty
        ? formatted
        : formatted[0].toUpperCase() + formatted.substring(1);
  }
}

class _DayRow extends StatelessWidget {
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
    final colors = context.appColors;
    final isClosed = dayHours == null;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          // Day Label
          Container(
            width: 45,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color:
                  isClosed
                      ? colors.secondaryTextColor.withValues(alpha: 0.05)
                      : colors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              dayLabel,
              style: context.appTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color:
                    isClosed ? colors.secondaryTextColor : colors.primaryColor,
              ),
            ),
          ),
          const Gap(12),
          // Hours or Closed status
          Expanded(
            child: Row(
              children: [
                if (!isClosed) ...[
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: colors.primaryTextColor.withValues(alpha: 0.5),
                  ),
                  const Gap(6),
                ],
                Text(
                  isClosed
                      ? context.l10n.closed
                      : '${dayHours!.open} – ${dayHours!.close}',
                  style: context.appTextStyles.medium.copyWith(
                    color:
                        isClosed
                            ? colors.secondaryTextColor.withValues(alpha: 0.5)
                            : colors.primaryTextColor,
                    fontWeight: isClosed ? FontWeight.w500 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Visual indicator dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isClosed
                      ? colors.errorColor.withValues(alpha: 0.2)
                      : colors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
