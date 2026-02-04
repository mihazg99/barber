import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/auth/data/country_code.dart';
import 'package:barber/features/auth/presentation/widgets/country_code_selector.dart';

class AuthPhoneInput extends HookConsumerWidget {
  const AuthPhoneInput({
    super.key,
    required this.onSendOtp,
    this.isLoading = false,
    this.errorMessage,
  });

  final void Function(String phone) onSendOtp;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final selectedCountry = useState<CountryCode>(
      kCountryCodes.firstWhere(
        (c) => c.isoCode == 'US',
        orElse: () => kCountryCodes.first,
      ),
    );

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.authEnterPhone,
            style: context.appTextStyles.h2.copyWith(
              color: context.appColors.primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(context.appSizes.paddingSmall),
          Text(
            context.l10n.authVerificationCodeSent,
            style: context.appTextStyles.caption.copyWith(
              color: context.appColors.captionTextColor,
              fontSize: 14,
            ),
          ),
          Gap(context.appSizes.paddingLarge),
          Text(
            context.l10n.authPhoneNumber,
            style: context.appTextStyles.h2.copyWith(
              color: context.appColors.secondaryTextColor,
            ),
          ),
          Gap(context.appSizes.paddingSmall),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CountryCodeSelector(
                selected: selectedCountry.value,
                onChanged: (c) => selectedCountry.value = c,
                enabled: !isLoading,
              ),
              Gap(context.appSizes.paddingMedium),
              Expanded(
                child: CustomTextField.normal(
                  hint: context.l10n.authPhoneHint,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  controller: controller,
                  validator: (v) {
                    final digits = _digitsOnly(v ?? '');
                    if (digits.length < 6) {
                      return context.l10n.authPhoneValidation;
                    }
                    return null;
                  },
                ),
              ),
            ],
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
                        final digits = _digitsOnly(controller.text);
                        final fullPhone =
                            selectedCountry.value.dialCode + digits;
                        onSendOtp(fullPhone);
                      }
                    },
            loading: isLoading,
            child: Text(context.l10n.authSendCode),
          ),
        ],
      ),
    );
  }

  static String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
}
