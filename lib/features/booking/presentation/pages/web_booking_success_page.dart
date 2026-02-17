import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';

class WebBookingSuccessPage extends StatelessWidget {
  const WebBookingSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(context.appSizes.paddingXl),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: context.appColors.menuBackgroundColor,
            borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(context.appSizes.paddingLarge),
                decoration: BoxDecoration(
                  color: context.appColors.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: context.appColors.successColor,
                  size: 48,
                ),
              ),
              Gap(context.appSizes.paddingLarge),
              Text(
                context.l10n.bookingAppointmentSuccess,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.appColors.primaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(context.appSizes.paddingSmall),
              Text(
                'Your appointment has been successfully scheduled.',
                style: TextStyle(
                  fontSize: 14,
                  color: context.appColors.secondaryTextColor,
                ),
                textAlign: TextAlign.center,
              ),
              Gap(context.appSizes.paddingXl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.go(AppRoute.home.path);
                  },
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: context.appSizes.paddingMedium,
                    ),
                    backgroundColor: context.appColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.appSizes.borderRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
