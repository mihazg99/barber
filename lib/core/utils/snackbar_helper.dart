import 'package:flutter/material.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';

/// Shows an improved error snackbar: floating, rounded, with optional action.
void showErrorSnackBar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final colors = context.appColors;
  final sizes = context.appSizes;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.paddingSmall),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      backgroundColor: colors.errorColor,
      behavior: SnackBarBehavior.floating,
      persist: false,
      margin: EdgeInsets.fromLTRB(
        sizes.paddingMedium,
        0,
        sizes.paddingMedium,
        MediaQuery.of(context).padding.bottom + sizes.paddingSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sizes.borderRadius),
      ),
      duration: const Duration(seconds: 4),
      action:
          (actionLabel != null && onAction != null)
              ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onAction();
                },
              )
              : null,
    ),
  );
}

/// Shows a success snackbar: floating, rounded.
void showSuccessSnackBar(BuildContext context, {required String message}) {
  final colors = context.appColors;
  final sizes = context.appSizes;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.paddingSmall),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      backgroundColor: colors.primaryColor,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(
        sizes.paddingMedium,
        0,
        sizes.paddingMedium,
        MediaQuery.of(context).padding.bottom + sizes.paddingSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sizes.borderRadius),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Shows an info snackbar: floating, rounded.
void showInfoSnackBar(BuildContext context, {required String message}) {
  final sizes = context.appSizes;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.paddingSmall),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      backgroundColor: Colors.grey[800],
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(
        sizes.paddingMedium,
        0,
        sizes.paddingMedium,
        MediaQuery.of(context).padding.bottom + sizes.paddingSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sizes.borderRadius),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}
