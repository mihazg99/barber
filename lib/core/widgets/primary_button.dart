import 'package:flutter/material.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final OutlinedBorder? shape;
  final Widget? icon;
  final double? height;
  final double? fontSize;
  final TextStyle? textStyle;
  final bool isBig;

  const PrimaryButton._({
    required this.onPressed,
    this.loading = false,
    this.color,
    this.textColor,
    this.padding,
    this.shape,
    this.icon,
    this.height,
    this.fontSize,
    this.textStyle,
    this.isBig = true,
    Key? key,
    required this.child,
  }) : super(key: key);

  factory PrimaryButton.small({
    required VoidCallback? onPressed,
    bool loading = false,
    Color? color,
    Color? textColor,
    OutlinedBorder? shape,
    Widget? icon,
    Key? key,
    TextStyle? textStyle,
    required Widget child,
    bool isBig = false,
  }) {
    return PrimaryButton._(
      onPressed: onPressed,
      loading: loading,
      color: color,
      textColor: textColor,
      padding: null,
      shape: shape,
      icon: icon,
      height: null,
      fontSize: null,
      textStyle: textStyle,
      key: key,
      isBig: isBig,
      child: child,
    );
  }

  factory PrimaryButton.big({
    required VoidCallback? onPressed,
    bool loading = false,
    Color? color,
    Color? textColor,
    OutlinedBorder? shape,
    Widget? icon,
    Key? key,
    TextStyle? textStyle,
    required Widget child,
    bool isBig = true,
    double? height,
  }) {
    return PrimaryButton._(
      onPressed: onPressed,
      loading: loading,
      color: color,
      textColor: textColor,
      padding: null,
      shape: shape,
      icon: icon,
      height: height,
      fontSize: null,
      textStyle: textStyle,
      isBig: isBig,
      key: key,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultHeight =
        isBig
            ? context.appSizes.buttonHeightBig
            : context.appSizes.buttonHeightSmall;
    final defaultPadding =
        isBig
            ? EdgeInsets.symmetric(
              horizontal: context.appSizes.paddingLarge,
              vertical: context.appSizes.paddingMedium,
            )
            : EdgeInsets.symmetric(
              horizontal: context.appSizes.paddingMedium,
              vertical: context.appSizes.paddingSmall,
            );
    final defaultTextStyle =
        isBig
            ? context.appTextStyles.button.copyWith(fontSize: 16)
            : context.appTextStyles.button.copyWith(fontSize: 14);
    final defaultColor = context.appColors.primaryColor;
    final defaultTextColor = context.appColors.primaryTextColor;
    final defaultShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
    );

    // Loading is always shown inside the button (spinner only, no loading text).
    final double indicatorSize = isBig ? 24 : 20;
    final Widget content =
        loading
            ? SizedBox(
              width: indicatorSize,
              height: indicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  textColor ?? defaultTextColor,
                ),
              ),
            )
            : Stack(
              alignment: Alignment.center,
              children: [
                if (icon != null)
                  Align(alignment: Alignment.centerLeft, child: icon!),
                Center(
                  child: DefaultTextStyle(
                    style:
                        textStyle ??
                        defaultTextStyle.copyWith(
                          color: textColor ?? defaultTextColor,
                        ),
                    child: child,
                  ),
                ),
              ],
            );

    return SizedBox(
      width: isBig ? MediaQuery.of(context).size.width : null,
      height: height ?? defaultHeight,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color ?? defaultColor,
          foregroundColor: textColor ?? defaultTextColor,
          padding: padding ?? defaultPadding,
          shape: shape ?? defaultShape,
        ),
        child: content,
      ),
    );
  }
}
