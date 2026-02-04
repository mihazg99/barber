import 'package:flutter/material.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';

/// Barber shift tab.
class DashboardShiftTab extends StatelessWidget {
  const DashboardShiftTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 64,
            color: context.appColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'My Shift',
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
