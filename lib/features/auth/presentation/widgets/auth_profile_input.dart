import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/auth/domain/entities/user_entity.dart';

class AuthProfileInput extends HookConsumerWidget {
  const AuthProfileInput({
    super.key,
    required this.user,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
  });

  final UserEntity user;
  final Future<void> Function(String fullName) onSubmit;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Complete your profile',
            style: context.appTextStyles.h2.copyWith(
              color: context.appColors.primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(context.appSizes.paddingSmall),
          Text(
            'Add your name so we can personalize your experience',
            style: context.appTextStyles.caption.copyWith(
              color: context.appColors.captionTextColor,
              fontSize: 14,
            ),
          ),
          Gap(context.appSizes.paddingLarge),
          CustomTextField.withTitle(
            title: 'Full name',
            hint: 'John Doe',
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.done,
            controller: controller,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          Gap(context.appSizes.paddingMedium),
          Text(
            'Phone',
            style: context.appTextStyles.h2.copyWith(
              color: context.appColors.secondaryTextColor,
            ),
          ),
          Gap(context.appSizes.paddingSmall),
          Container(
            padding: EdgeInsets.symmetric(
              vertical: context.appSizes.paddingSmall,
              horizontal: context.appSizes.paddingMedium,
            ),
            decoration: BoxDecoration(
              color: context.appColors.secondaryColor,
              borderRadius: BorderRadius.circular(context.appSizes.borderRadius),
              border: Border.all(color: context.appColors.borderColor),
            ),
            child: Text(
              user.phone.isEmpty ? '—' : user.phone,
              style: context.appTextStyles.body.copyWith(
                color: context.appColors.secondaryTextColor,
              ),
            ),
          ),
          if (errorMessage != null) ...[
            Gap(context.appSizes.paddingSmall),
            Text(
              errorMessage!,
              style: TextStyle(
                color: context.appColors.errorColor,
                fontSize: 14,
              ),
            ),
          ],
          Gap(context.appSizes.paddingLarge),
          PrimaryButton.big(
            onPressed: isLoading
                ? null
                : () async {
                    if (formKey.currentState?.validate() ?? false) {
                      await onSubmit(controller.text.trim());
                    }
                  },
            loading: isLoading,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
