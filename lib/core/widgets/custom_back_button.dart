import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/gen/assets.gen.dart';

/// Common back button used across screens. Uses [context.pop] when [onPressed] is null.
class CustomBackButton extends StatelessWidget {
  final String? title;
  final VoidCallback? onPressed;

  const CustomBackButton._({super.key, this.title, this.onPressed});

  /// Icon-only back button. [onPressed] defaults to [context.pop].
  factory CustomBackButton({Key? key, VoidCallback? onPressed}) {
    return CustomBackButton._(key: key, onPressed: onPressed);
  }

  @Deprecated('Use CustomBackButton() instead')
  factory CustomBackButton.defaultButton({Key? key, VoidCallback? onPressed}) {
    return CustomBackButton._(key: key, onPressed: onPressed);
  }

  factory CustomBackButton.withTitle(String title, {Key? key, VoidCallback? onPressed}) {
    return CustomBackButton._(key: key, title: title, onPressed: onPressed);
  }

  VoidCallback _handlePressed(BuildContext context) =>
      onPressed ?? () => context.pop();

  @override
  Widget build(BuildContext context) {
    if (title == null) {
      return IconButton(
        onPressed: _handlePressed(context),
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
              onPressed: _handlePressed(context),
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
