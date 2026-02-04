import 'package:flutter/material.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';

/// Barber dashboard home tab.
class DashboardBarberHomeTab extends StatelessWidget {
  const DashboardBarberHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 64,
            color: context.appColors.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Barber Home',
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
