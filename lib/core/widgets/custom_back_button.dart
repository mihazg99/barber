import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory/core/theme/app_text_styles.dart';
import 'package:inventory/gen/assets.gen.dart';

class CustomBackButton extends StatelessWidget {
  final String? title;

  const CustomBackButton._({super.key, this.title});

  factory CustomBackButton.defaultButton({Key? key}) {
    return CustomBackButton._(key: key);
  }

  factory CustomBackButton.withTitle(String title, {Key? key}) {
    return CustomBackButton._(key: key, title: title);
  }

  @override
  Widget build(BuildContext context) {
    if (title == null) {
      return IconButton(
        onPressed: context.pop,
        padding: EdgeInsets.zero,
        icon: SvgPicture.asset(Assets.icons.back),
      );
    }

    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: context.pop,
              padding: EdgeInsets.zero,
              icon: SvgPicture.asset(Assets.icons.back),
            ),
          ),
          Center(
            child: Text(
              title!,
              style: context.appTextStyles.h2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
