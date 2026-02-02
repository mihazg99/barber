import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_app_bar.dart';

/// Placeholder for booking flow (select location / service / time).
/// Supports quick-action from home: ?barberId=xxx and ?serviceId=yyy.
class BookingPage extends ConsumerWidget {
  const BookingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = GoRouterState.of(context).uri.queryParameters;
    final barberId = query['barberId'];
    final serviceId = query['serviceId'];

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: CustomAppBar.withTitleAndBackButton(
        'Book appointment',
        onBack: () => context.go(AppRoute.home.path),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.appSizes.paddingMedium),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 64,
                color: context.appColors.captionTextColor,
              ),
              Gap(context.appSizes.paddingMedium),
              Text(
                'Booking coming soon',
                style: context.appTextStyles.h2.copyWith(
                  color: context.appColors.secondaryTextColor,
                ),
              ),
              Gap(context.appSizes.paddingSmall),
              Text(
                'Select location, service and time',
                style: context.appTextStyles.caption.copyWith(
                  color: context.appColors.captionTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (barberId != null || serviceId != null) ...[
                Gap(context.appSizes.paddingMedium),
                Text(
                  'Quick book: ${barberId != null ? 'Barber selected' : ''}${barberId != null && serviceId != null ? ' · ' : ''}${serviceId != null ? 'Service selected' : ''}',
                  style: context.appTextStyles.caption.copyWith(
                    fontSize: 12,
                    color: context.appColors.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
