import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/gen/assets.gen.dart';

class CustomTextField extends HookWidget {
  final String? hint;
  final String? title;
  final ValueChanged<String>? onChanged;
  final Widget? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool isSearch;
  final String? Function(String?)? validator;

  const CustomTextField._({
    this.hint,
    this.title,
    this.onChanged,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.isSearch = false,
    this.validator,
    Key? key,
  }) : super(key: key);

  factory CustomTextField.normal({
    String? hint,
    ValueChanged<String>? onChanged,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int? maxLines = 1,
    int? minLines,
    bool enabled = true,
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    return CustomTextField._(
      hint: hint,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      key: key,
      controller: controller,
      focusNode: focusNode,
      isSearch: false,
      validator: validator,
    );
  }

  factory CustomTextField.withTitle({
    required String title,
    String? hint,
    ValueChanged<String>? onChanged,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int? maxLines = 1,
    int? minLines,
    bool enabled = true,
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    return CustomTextField._(
      title: title,
      hint: hint,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      key: key,
      controller: controller,
      focusNode: focusNode,
      isSearch: false,
      validator: validator,
    );
  }

  factory CustomTextField.search({
    String? hint = 'Search',
    ValueChanged<String>? onChanged,
    bool enabled = true,
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    return CustomTextField._(
      hint: hint,
      onChanged: onChanged,
      prefixIcon: Padding(
        padding: EdgeInsets.all(AppSizes.main.paddingSmall),
        child: SvgPicture.asset(Assets.icons.search),
      ),
      enabled: enabled,
      key: key,
      controller: controller,
      focusNode: focusNode,
      isSearch: true,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveController = controller ?? useTextEditingController();
    final effectiveFocusNode = focusNode ?? useFocusNode();
    final hasText = useState(effectiveController.text.isNotEmpty);

    useEffect(() {
      void listener() => hasText.value = effectiveController.text.isNotEmpty;
      effectiveController.addListener(listener);
      return () => effectiveController.removeListener(listener);
    }, [effectiveController]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: context.appTextStyles.h2.copyWith(
              color: context.appColors.secondaryTextColor,
            ),
          ),
          SizedBox(height: context.appSizes.paddingSmall),
        ],
        TextFormField(
          controller: effectiveController,
          focusNode: effectiveFocusNode,
          style: context.appTextStyles.fields,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.appTextStyles.fields.copyWith(
              color: context.appColors.hintTextColor,
            ),
            filled: true,
            fillColor: context.appColors.secondaryColor,
            contentPadding: EdgeInsets.symmetric(
              vertical: context.appSizes.paddingSmall,
              horizontal: context.appSizes.paddingMedium,
            ),
            prefixIcon: prefixIcon,
            suffixIcon:
                (isSearch && prefixIcon != null && hasText.value)
                    ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: context.appColors.hintTextColor,
                      ),
                      splashRadius: 18,
                      onPressed: () {
                        effectiveController.clear();
                        if (onChanged != null) onChanged!('');
                      },
                    )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
              borderSide: BorderSide(color: context.appColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
              borderSide: BorderSide(color: context.appColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
              borderSide: BorderSide(
                color: context.appColors.primaryColor,
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
              borderSide: BorderSide(
                color: context.appColors.errorColor,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                context.appSizes.borderRadius,
              ),
              borderSide: BorderSide(
                color: context.appColors.errorColor,
                width: 1,
              ),
            ),
            errorStyle: context.appTextStyles.fields.copyWith(
              color: context.appColors.errorColor,
              fontSize: 12,
            ),
          ),
          onChanged: (val) {
            if (onChanged != null) onChanged!(val);
          },
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          minLines: minLines,
          enabled: enabled,
        ),
      ],
    );
  }
}
