import 'package:flutter/material.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';

/// Uppercase section title (e.g. "UPCOMING", "NEARBY BARBERSHOP").
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: context.appTextStyles.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: context.appColors.captionTextColor,
      ),
    );
  }
}
