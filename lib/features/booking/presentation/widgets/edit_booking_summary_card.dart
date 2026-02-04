import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/booking/presentation/bloc/edit_booking_notifier.dart';

/// Compact summary of what stays the same when rescheduling.
class EditBookingSummaryCard extends StatelessWidget {
  const EditBookingSummaryCard({
    super.key,
    required this.state,
  });

  final EditBookingState state;

  static const _cardRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final appointment = state.appointment;

    return Container(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      decoration: BoxDecoration(
        color: colors.menuBackgroundColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SummaryRow(
            icon: Icons.location_on_outlined,
            label: state.locationName ?? '-',
          ),
          Gap(context.appSizes.paddingSmall),
          _SummaryRow(
            icon: Icons.person_outline_rounded,
            label: state.barberName ?? '-',
          ),
          Gap(context.appSizes.paddingSmall),
          if (state.serviceNames.isNotEmpty)
            _SummaryRow(
              icon: Icons.cut_rounded,
              label: state.serviceNames.join(', '),
            ),
          Gap(context.appSizes.paddingMedium),
          _CurrentDateTimeRow(
            date: _formatDate(context, appointment.startTime),
            time: _formatTime(
              context,
              appointment.startTime,
              appointment.endTime,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMd(locale).format(dt);
  }

  static String _formatTime(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final timeFormat = DateFormat.Hm(locale);
    return '${timeFormat.format(start)} – ${timeFormat.format(end)}';
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.captionTextColor),
        Gap(context.appSizes.paddingSmall),
        Expanded(
          child: Text(
            label,
            style: context.appTextStyles.body.copyWith(
              color: colors.primaryTextColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrentDateTimeRow extends StatelessWidget {
  const _CurrentDateTimeRow({
    required this.date,
    required this.time,
  });

  final String date;
  final String time;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.appSizes.paddingSmall,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: colors.captionTextColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 16,
            color: colors.captionTextColor,
          ),
          Gap(context.appSizes.paddingSmall),
          Text(
            '$date · $time',
            style: context.appTextStyles.caption.copyWith(
              fontSize: 13,
              color: colors.captionTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
