import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/utils/price_formatter.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/booking/presentation/bloc/manage_booking_notifier.dart';

/// Card displaying appointment details: location, barber, services, date/time, price.
class ManageBookingDetailCard extends StatelessWidget {
  const ManageBookingDetailCard({
    super.key,
    required this.data,
    this.isProfessionalView = false,
  });

  final ManageBookingData data;
  final bool isProfessionalView;

  static const _cardRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final appointment = data.appointment;

    return Container(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      decoration: BoxDecoration(
        color: colors.menuBackgroundColor,
        borderRadius: BorderRadius.circular(_cardRadius),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: data.locationName ?? '-',
          ),
          Gap(context.appSizes.paddingSmall),
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label:
                isProfessionalView
                    ? data.appointment.customerName
                    : data.barberName ?? '-',
          ),
          Gap(context.appSizes.paddingSmall),
          if (data.serviceNames.isNotEmpty) ...[
            _DetailRow(
              icon: Icons.cut_rounded,
              label: data.serviceNames.join(', '),
            ),
            Gap(context.appSizes.paddingSmall),
          ],
          _DetailRow(
            icon: Icons.event_rounded,
            label: _formatDateTime(context, appointment.startTime),
          ),
          Gap(context.appSizes.paddingSmall),
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: _formatTimeRange(
              context,
              appointment.startTime,
              appointment.endTime,
            ),
          ),
          Gap(context.appSizes.paddingMedium),
          const _PriceDivider(),
          Gap(context.appSizes.paddingSmall),
          _PriceRow(totalPrice: appointment.totalPrice),
        ],
      ),
    );
  }

  static String _formatDateTime(BuildContext context, DateTime dt) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.yMMMd(locale).format(dt);
  }

  static String _formatTimeRange(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final timeFormat = DateFormat.Hm(locale);
    return '${timeFormat.format(start)} – ${timeFormat.format(end)}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
        Icon(
          icon,
          size: 20,
          color: colors.primaryColor,
        ),
        Gap(context.appSizes.paddingSmall),
        Expanded(
          child: Text(
            label,
            style: context.appTextStyles.body.copyWith(
              color: colors.primaryTextColor,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceDivider extends StatelessWidget {
  const _PriceDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Divider(
      color: colors.borderColor.withValues(alpha: 0.3),
      height: 1,
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.totalPrice});

  final num totalPrice;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.bookingTotal,
          style: context.appTextStyles.h2.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.primaryTextColor,
          ),
        ),
        Text(
          context.formatPriceWithCurrency(totalPrice),
          style: context.appTextStyles.h2.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _CallClientButton extends StatelessWidget {
  const _CallClientButton({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final uri = Uri(scheme: 'tel', path: phone);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      style: IconButton.styleFrom(
        backgroundColor: context.appColors.primaryColor.withValues(alpha: 0.1),
        foregroundColor: context.appColors.primaryColor,
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(Icons.phone_rounded, size: 20),
    );
  }
}
