import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/auth/di.dart' as auth_di;
import 'package:barber/features/brand/di.dart' as brand_di;
import 'package:barber/features/time_off/di.dart';
import 'package:barber/features/time_off/domain/entities/time_off_entity.dart';

/// Bottom sheet dialog for adding new time-off.
class AddTimeOffDialog extends HookConsumerWidget {
  const AddTimeOffDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final startDate = useState<DateTime?>(null);
    final endDate = useState<DateTime?>(null);
    final selectedReason = useState<String>('vacation');
    final isSaving = useState(false);

    return Container(
      decoration: BoxDecoration(
        color: colors.menuBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(context.appSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.shiftAddTimeOff,
                      style: context.appTextStyles.h1.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: colors.primaryTextColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: colors.secondaryTextColor,
                    ),
                  ),
                ],
              ),
              Gap(context.appSizes.paddingLarge),

              // Start Date
              _DatePickerField(
                label: context.l10n.timeOffStartDate,
                selectedDate: startDate.value,
                onDateSelected: (date) => startDate.value = date,
              ),
              Gap(context.appSizes.paddingMedium),

              // End Date
              _DatePickerField(
                label: context.l10n.timeOffEndDate,
                selectedDate: endDate.value,
                onDateSelected: (date) => endDate.value = date,
              ),
              Gap(context.appSizes.paddingMedium),

              // Reason
              Text(
                context.l10n.timeOffReason,
                style: context.appTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryTextColor,
                ),
              ),
              Gap(8),
              _ReasonSelector(
                selectedReason: selectedReason.value,
                onReasonSelected: (reason) => selectedReason.value = reason,
              ),
              Gap(context.appSizes.paddingLarge),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      isSaving.value
                          ? null
                          : () async {
                            print('🔵 Save button pressed!');
                            print('🔵 Start date: ${startDate.value}');
                            print('🔵 End date: ${endDate.value}');
                            print('🔵 Reason: ${selectedReason.value}');
                            await _saveTimeOff(
                              context,
                              ref,
                              startDate.value,
                              endDate.value,
                              selectedReason.value,
                              isSaving,
                            );
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      isSaving.value
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            context.l10n.save,
                            style: context.appTextStyles.medium.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTimeOff(
    BuildContext context,
    WidgetRef ref,
    DateTime? startDate,
    DateTime? endDate,
    String reason,
    ValueNotifier<bool> isSaving,
  ) async {
    print('🟢 _saveTimeOff called');

    // Validation
    if (startDate == null) {
      print('🔴 Start date is null');
      _showError(context, context.l10n.timeOffStartDateRequired);
      return;
    }
    if (endDate == null) {
      print('🔴 End date is null');
      _showError(context, context.l10n.timeOffEndDateRequired);
      return;
    }
    if (endDate.isBefore(startDate)) {
      print('🔴 End date before start date');
      _showError(context, context.l10n.timeOffEndBeforeStart);
      return;
    }

    print('🟢 Validation passed, setting isSaving to true');
    isSaving.value = true;

    try {
      print('🟢 Reading current user...');
      // Get user directly - this is more reliable than currentBarberProvider
      final currentUserAsync = ref.read(auth_di.currentUserProvider);
      final currentUser = currentUserAsync.valueOrNull;
      print('🟢 Current user: ${currentUser?.userId}');
      print('🟢 User barberId: ${currentUser?.barberId}');

      if (currentUser == null || currentUser.barberId.isEmpty) {
        print('🔴 User or barberId is null/empty');
        if (context.mounted) {
          _showError(
            context,
            'Barber not found. Please ensure you are logged in as a barber.',
          );
        }
        return;
      }

      // Get brand from defaultBrandProvider
      print('🟢 Reading default brand...');
      final brandAsync = await ref.read(brand_di.defaultBrandProvider.future);
      print('🟢 Brand: ${brandAsync?.brandId}');

      if (brandAsync == null) {
        print('🔴 Brand is null');
        if (context.mounted) {
          _showError(context, 'Brand not found');
        }
        return;
      }

      print('🟢 Creating time-off entity...');
      final timeOffEntity = TimeOffEntity(
        timeOffId: const Uuid().v4(),
        barberId: currentUser.barberId,
        brandId: brandAsync.brandId,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        createdAt: DateTime.now(),
      );
      print('🟢 Time-off entity created: ${timeOffEntity.timeOffId}');

      print('🟢 Calling repository create...');
      final timeOffRepo = ref.read(timeOffRepositoryProvider);
      final result = await timeOffRepo.create(timeOffEntity);
      print('🟢 Repository create completed');

      result.fold(
        (failure) {
          print('🔴 Create failed: ${failure.message}');
          if (context.mounted) {
            _showError(context, failure.message);
          }
        },
        (_) {
          print('🟢 Create succeeded!');
          if (context.mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.timeOffSaved),
                backgroundColor: context.appColors.primaryColor,
              ),
            );
          }
        },
      );
    } catch (e) {
      print('🔴 Exception: $e');
      if (context.mounted) {
        _showError(context, 'Error: $e');
      }
    } finally {
      print('🟢 Setting isSaving to false');
      isSaving.value = false;
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: context.appColors.errorColor,
      ),
    );
  }
}

class _DatePickerField extends HookWidget {
  const _DatePickerField({
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.appTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.primaryTextColor,
          ),
        ),
        Gap(8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: Locale(locale),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.borderColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: colors.secondaryTextColor,
                ),
                Gap(12),
                Text(
                  selectedDate != null
                      ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                      : 'Select date',
                  style: context.appTextStyles.medium.copyWith(
                    fontSize: 15,
                    color:
                        selectedDate != null
                            ? colors.primaryTextColor
                            : colors.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReasonSelector extends HookWidget {
  const _ReasonSelector({
    required this.selectedReason,
    required this.onReasonSelected,
  });

  final String selectedReason;
  final ValueChanged<String> onReasonSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final reasons = [
      ('vacation', context.l10n.timeOffReasonVacation, Icons.beach_access),
      ('sick', context.l10n.timeOffReasonSick, Icons.local_hospital),
      ('personal', context.l10n.timeOffReasonPersonal, Icons.person),
    ];

    return Row(
      children:
          reasons.map((reason) {
            final isSelected = selectedReason == reason.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => onReasonSelected(reason.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? colors.primaryColor.withValues(alpha: 0.1)
                              : colors.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? colors.primaryColor
                                : colors.borderColor.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          reason.$3,
                          color:
                              isSelected
                                  ? colors.primaryColor
                                  : colors.secondaryTextColor,
                          size: 24,
                        ),
                        Gap(4),
                        Text(
                          reason.$2,
                          style: context.appTextStyles.caption.copyWith(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isSelected
                                    ? colors.primaryColor
                                    : colors.secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
