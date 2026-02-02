import 'package:flutter/material.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_back_button.dart';

/// Common app bar with named constructors for title-only and title + back button.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// App bar with only a title (no back button).
  const CustomAppBar.withTitle(this.title, {super.key})
      : showBackButton = false,
        onBack = null;

  /// App bar with title and a back button. Uses [context.pop] when [onBack] is null.
  const CustomAppBar.withTitleAndBackButton(this.title, {super.key, this.onBack})
      : showBackButton = true;

  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.appColors.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: showBackButton ? CustomBackButton(onPressed: onBack) : null,
      leadingWidth: showBackButton ? kToolbarHeight : null,
      title: Text(
        title,
        style: context.appTextStyles.h1.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: context.appColors.primaryTextColor,
        ),
      ),
    );
  }
}
