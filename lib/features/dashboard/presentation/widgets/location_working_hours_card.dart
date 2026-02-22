import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/value_objects/working_hours.dart';

/// Displays location working hours in a card format with optional edit button.
/// Set [showCardContainer] to false to render content only (e.g. inside a bottom sheet).
/// When [closedDates] is provided and today is in that list, the "today" row shows
/// "Closed (holiday)" so users see the shop is closed on that date.
class LocationWorkingHoursCard extends StatelessWidget {
  const LocationWorkingHoursCard({
    required this.workingHours,
    this.closedDates,
    this.todayOverride,
    this.onEdit,
    this.showCardContainer = true,
    super.key,
  });

  final WorkingHoursMap? workingHours;
  /// Dates when the location is closed (YYYY-MM-DD). When today is in this list, today's row shows closed.
  final List<String>? closedDates;
  /// For tests; if null, uses DateTime.now() to determine today.
  final DateTime? todayOverride;
  final VoidCallback? onEdit;
  final bool showCardContainer;

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  static String _todayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sizes = context.appSizes;
    final l10n = context.l10n;

    final hasHours =
        workingHours != null &&
        workingHours!.values.any((hours) => hours != null);

    final contentPadding = showCardContainer
        ? EdgeInsets.all(sizes.paddingMedium)
        : EdgeInsets.zero;
    final listPadding = showCardContainer
        ? EdgeInsets.fromLTRB(
            sizes.paddingMedium,
            0,
            sizes.paddingMedium,
            sizes.paddingMedium,
          )
        : EdgeInsets.only(
            top: sizes.paddingSmall,
            bottom: sizes.paddingMedium,
          );

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: contentPadding,
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
            _buildEmptyState(context, compact: !showCardContainer)
          else
            Padding(
              padding: listPadding,
              child: Column(
                children: List.generate(7, (index) {
                  final dayKey = _dayKeys[index];
                  final dayHours = workingHours![dayKey];
                  final today = todayOverride ?? DateTime.now();
                  final isTodayRow = today.weekday == index + 1;
                  final todayStr = _todayKey(today);
                  final isClosedDate =
                      closedDates != null &&
                      closedDates!.isNotEmpty &&
                      isTodayRow &&
                      closedDates!.contains(todayStr);
                  final closedLabelOverride = isClosedDate
                      ? (context.l10n.closedHolidayOrDate)
                      : null;
                  return _DayRow(
                    dayLabel: _getDayLabel(context, index),
                    dayHours: dayHours,
                    closedLabelOverride: closedLabelOverride,
                    isLast: index == 6,
                  );
                }),
              ),
            ),
        ],
      );

    if (showCardContainer) {
      return Container(
        decoration: BoxDecoration(
          color: colors.menuBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.borderColor.withValues(alpha: 0.1),
          ),
        ),
        child: content,
      );
    }
    return content;
  }

  Widget _buildEmptyState(BuildContext context, {bool compact = false}) {
    final colors = context.appColors;
    final padding = compact
        ? const EdgeInsets.only(top: 8, bottom: 20)
        : const EdgeInsets.fromLTRB(16, 8, 16, 20);
    return Padding(
      padding: padding,
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
    this.closedLabelOverride,
    required this.isLast,
  });

  final String dayLabel;
  final DayWorkingHours? dayHours;
  /// When set, show this as closed label (e.g. "Closed (holiday)") and treat as closed.
  final String? closedLabelOverride;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isClosed = closedLabelOverride != null || dayHours == null;
    final closedText = closedLabelOverride ?? context.l10n.closed;

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
                      ? closedText
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
