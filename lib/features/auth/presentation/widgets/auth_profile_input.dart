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
import 'package:barber/features/auth/domain/entities/user_entity.dart';
import 'package:barber/features/auth/presentation/widgets/country_code_selector.dart';

class AuthProfileInput extends HookConsumerWidget {
  const AuthProfileInput({
    super.key,
    required this.user,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
  });

  final UserEntity user;
  final Future<void> Function(String fullName, String phone) onSubmit;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final phoneController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final selectedCountry = useState<CountryCode>(
      kCountryCodes.firstWhere(
        (c) => c.isoCode == 'HR',
        orElse: () => kCountryCodes.first,
      ),
    );

    // Pre-fill phone if user already has one
    useEffect(() {
      if (user.phone.isNotEmpty) {
        // Try to extract country code and phone number
        final phone = user.phone;
        final matchingCountry = kCountryCodes.firstWhere(
          (c) => phone.startsWith(c.dialCode),
          orElse: () => selectedCountry.value,
        );
        selectedCountry.value = matchingCountry;
        final phoneWithoutCode = phone.replaceFirst(matchingCountry.dialCode, '');
        phoneController.text = phoneWithoutCode;
      }
      return null;
    }, []);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.authCompleteProfile,
            style: context.appTextStyles.h2.copyWith(
              color: context.appColors.primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(context.appSizes.paddingSmall),
          Text(
            context.l10n.authProfileDescription,
            style: context.appTextStyles.caption.copyWith(
              color: context.appColors.captionTextColor,
              fontSize: 14,
            ),
          ),
          Gap(context.appSizes.paddingLarge),
          CustomTextField.withTitle(
            title: context.l10n.authFullName,
            hint: context.l10n.authFullNameHint,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            controller: nameController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return context.l10n.authFullNameValidation;
              }
              return null;
            },
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
                  controller: phoneController,
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
                    : () async {
                      if (formKey.currentState?.validate() ?? false) {
                        final digits = _digitsOnly(phoneController.text);
                        final fullPhone = selectedCountry.value.dialCode + digits;
                        await onSubmit(
                          nameController.text.trim(),
                          fullPhone,
                        );
                      }
                    },
            loading: isLoading,
            child: Text(context.l10n.continueButton),
          ),
        ],
      ),
    );
  }

  static String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');
}
