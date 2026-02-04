import 'package:flutter/material.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';

/// Barber bookings tab.
class DashboardBookingsTab extends StatelessWidget {
  const DashboardBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: context.appColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.dashboardBookingsTitle,
            style: context.appTextStyles.bold.copyWith(
              fontSize: 24,
              color: context.appColors.primaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
