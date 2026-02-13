import 'package:flutter/material.dart';

import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/time_off/di.dart';
import 'package:barber/features/time_off/domain/entities/time_off_entity.dart';

/// Card displaying a single time-off period with premium styling.
class TimeOffCard extends HookConsumerWidget {
  const TimeOffCard({
    required this.timeOff,
    required this.locale,
    super.key,
  });

  final TimeOffEntity timeOff;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    // Use full locale from context for proper weekday localization
    final fullLocale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('EEE, MMM d', fullLocale);

    final startDateStr = dateFormat.format(timeOff.startDate);
    final endDateStr = dateFormat.format(timeOff.endDate);

    // Check if single day
    final isSingleDay = isSameDay(timeOff.startDate, timeOff.endDate);
    final dateDisplay =
        isSingleDay ? startDateStr : '$startDateStr - $endDateStr';

    final reasonLabel = _getReasonLabel(context, timeOff.reason);
    final reasonColor = _getReasonColor(timeOff.reason);
    final reasonIcon = _getReasonIcon(timeOff.reason);

    return Material(
      color: Colors.transparent,
      child: Focus(
        canRequestFocus: false,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: colors.borderColor.withOpacity(0.1),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Decorative background accent (hidden for vacation to avoid green overlay)
                if (timeOff.reason != 'vacation')
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: reasonColor.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

            Padding(
              padding: EdgeInsets.all(context.appSizes.paddingMedium),
              child: Row(
                children: [
                  // Left side: Icon box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: reasonColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: reasonColor.withOpacity(0.1),
                      ),
                    ),
                    child: Icon(
                      reasonIcon,
                      color: reasonColor,
                      size: 24,
                    ),
                  ),
                  Gap(context.appSizes.paddingMedium),

                  // Center: Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reasonLabel,
                          style: context.appTextStyles.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: reasonColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          dateDisplay,
                          style: context.appTextStyles.h3.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryTextColor,
                          ),
                        ),
                        if (!isSingleDay) ...[
                          const Gap(2),
                          Text(
                            _getDurationString(
                              context,
                              timeOff.startDate,
                              timeOff.endDate,
                            ),
                            style: context.appTextStyles.caption.copyWith(
                              color: colors.secondaryTextColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Right: Delete action
                  GestureDetector(
                    onTap: () => _showDeleteConfirmation(context, ref),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.errorColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: colors.errorColor.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getDurationString(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) {
    final days = end.difference(start).inDays + 1;
    return '$days ${context.l10n.timeOffDays}';
  }

  String _getReasonLabel(BuildContext context, String reason) {
    switch (reason) {
      case 'vacation':
        return context.l10n.timeOffReasonVacation;
      case 'sick':
        return context.l10n.timeOffReasonSick;
      case 'personal':
        return context.l10n.timeOffReasonPersonal;
      default:
        return reason;
    }
  }

  Color _getReasonColor(String reason) {
    switch (reason) {
      case 'vacation':
        return const Color(0xFF4CAF50); // Green
      case 'sick':
        return const Color(0xFFF44336); // Red
      case 'personal':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  IconData _getReasonIcon(String reason) {
    switch (reason) {
      case 'vacation':
        return Icons.beach_access_rounded;
      case 'sick':
        return Icons.local_hospital_rounded;
      case 'personal':
        return Icons.person_rounded;
      default:
        return Icons.event_busy_rounded;
    }
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: colors.menuBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              context.l10n.timeOffDeleteConfirm,
              style: context.appTextStyles.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.primaryTextColor,
              ),
            ),
            content: Text(
              context.l10n.timeOffDeleteConfirmMessage,
              style: context.appTextStyles.medium.copyWith(
                color: colors.secondaryTextColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  context.l10n.cancel,
                  style: context.appTextStyles.medium.copyWith(
                    color: colors.secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.errorColor.withOpacity(0.1),
                  foregroundColor: colors.errorColor,
                  elevation: 0,
                ),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final timeOffRepo = ref.read(timeOffRepositoryProvider);
                  await timeOffRepo.delete(timeOff.timeOffId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.timeOffDeleted),
                        backgroundColor: colors.primaryColor,
                      ),
                    );
                  }
                },
                child: Text(
                  context.l10n.timeOffDelete,
                  style: context.appTextStyles.medium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
