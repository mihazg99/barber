import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';

class AuthOtpInput extends HookConsumerWidget {
  const AuthOtpInput({
    super.key,
    required this.phone,
    required this.onVerify,
    required this.onBack,
    this.isLoading = false,
    this.errorMessage,
  });

  final String phone;
  final void Function(String code) onVerify;
  final VoidCallback onBack;
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
          Row(
            children: [
              IconButton(
                onPressed: isLoading ? null : onBack,
                icon: Icon(
                  Icons.arrow_back,
                  color: context.appColors.primaryTextColor,
                ),
              ),
              Expanded(
                child: Text(
                  'Enter verification code',
                  style: context.appTextStyles.h2.copyWith(
                    color: context.appColors.primaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Gap(context.appSizes.paddingSmall),
          Text(
            'We sent a code to $phone',
            style: context.appTextStyles.caption.copyWith(
              color: context.appColors.captionTextColor,
              fontSize: 14,
            ),
          ),
          Gap(context.appSizes.paddingLarge),
          CustomTextField.withTitle(
            title: 'Verification code',
            hint: '123456',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            controller: controller,
            validator: (v) {
              if (v == null || v.trim().length < 6) {
                return 'Enter the 6-digit code';
              }
              return null;
            },
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
            onPressed:
                isLoading
                    ? null
                    : () {
                      if (formKey.currentState?.validate() ?? false) {
                        onVerify(controller.text.trim());
                      }
                    },
            loading: isLoading,
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }
}
