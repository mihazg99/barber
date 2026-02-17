import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/widgets/custom_textfield.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/core/widgets/custom_app_bar.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/dashboard/presentation/bloc/dashboard_manual_booking_notifier.dart';
import 'package:barber/features/booking/presentation/widgets/booking_date_section.dart';
import 'package:barber/features/booking/presentation/widgets/booking_time_section.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';

class DashboardManualBookingPage extends HookConsumerWidget {
  const DashboardManualBookingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardManualBookingNotifierProvider);
    final notifier = ref.read(dashboardManualBookingNotifierProvider.notifier);

    final nameController = useTextEditingController();
    final phoneController = useTextEditingController();
    final isSubmitting = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.load();
      });
      return null;
    }, []);

    // Helper to check if we can select date
    final canSelectDate =
        state is BaseData<DashboardManualBookingData> &&
        state.data.selectedService != null &&
        state.data.selectedBarber != null;

    // Helper to check if we can select time
    final canSelectTime =
        state is BaseData<DashboardManualBookingData> &&
        state.data.selectedDate != null;

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: CustomAppBar.withTitleAndBackButton(
        context.l10n.dashboardManualBookingTitle,
      ),
      body: Builder(
        builder: (context) {
          if (state is BaseLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is BaseError) {
            return Center(
              child: Text(
                (state as BaseError).message,
                style: context.appTextStyles.body.copyWith(
                  color: context.appColors.errorColor,
                ),
              ),
            );
          }
          if (state is BaseData<DashboardManualBookingData>) {
            final data = state.data;
            return SingleChildScrollView(
              padding: EdgeInsets.all(context.appSizes.paddingMedium),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CustomerSection(
                      nameController: nameController,
                      phoneController: phoneController,
                    ),
                    Gap(context.appSizes.paddingLarge),
                    _ServiceSelection(
                      services: data.services,
                      selectedService: data.selectedService,
                      onChanged: notifier.selectService,
                    ),
                    Gap(context.appSizes.paddingLarge),
                    _BarberSelection(
                      barbers: data.barbers,
                      selectedBarber: data.selectedBarber,
                      onChanged: notifier.selectBarber,
                    ),
                    Gap(context.appSizes.paddingLarge),
                    AnimatedOpacity(
                      opacity: canSelectDate ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: !canSelectDate,
                        child: BookingDateSection(
                          selectedDate: data.selectedDate,
                          onDateSelected: notifier.selectDate,
                          title: context.l10n.dashboardManualBookingSelectDate,
                        ),
                      ),
                    ),
                    Gap(context.appSizes.paddingLarge),
                    if (data.selectedDate != null ||
                        canSelectDate) // Show time section if date selected or at least date selection is enabled (so user sees it coming)
                      AnimatedOpacity(
                        opacity: canSelectTime ? 1.0 : 0.5,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(
                          ignoring: !canSelectTime,
                          child: BookingTimeSection(
                            timeSlots: data.availableSlots,
                            selectedTimeSlot: data.selectedTimeSlot,
                            onTimeSlotSelected:
                                (slot) => notifier.selectTimeSlot(slot.time),
                            isLoading: data.isLoadingSlots,
                            title:
                                context.l10n.dashboardManualBookingSelectTime,
                          ),
                        ),
                      ),
                    Gap(context.appSizes.paddingLarge),
                    PrimaryButton.big(
                      child: Text(context.l10n.add),
                      loading: isSubmitting.value,
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          isSubmitting.value = true;
                          final error = await notifier.submit(
                            customerName: nameController.text,
                            customerPhone: phoneController.text,
                          );
                          isSubmitting.value = false;

                          if (context.mounted) {
                            if (error == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.dashboardManualBookingSuccess,
                                  ),
                                ),
                              );
                              context.pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  backgroundColor: context.appColors.errorColor,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                    Gap(context.appSizes.paddingLarge),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({
    required this.nameController,
    required this.phoneController,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.dashboardManualBookingCustomerInfo,
          style: context.appTextStyles.h2.copyWith(
            fontSize: 18,
            color: context.appColors.primaryTextColor,
          ),
        ),
        Gap(context.appSizes.paddingMedium),
        CustomTextField.withTitle(
          title: context.l10n.dashboardManualBookingCustomerName,
          hint: context.l10n.dashboardManualBookingCustomerNameHint,
          controller: nameController,
          validator:
              (v) =>
                  (v == null || v.isEmpty)
                      ? context.l10n.dashboardManualBookingCustomerNameRequired
                      : null,
        ),
        Gap(context.appSizes.paddingMedium),
        CustomTextField.withTitle(
          title: context.l10n.dashboardManualBookingCustomerPhone,
          hint: context.l10n.dashboardManualBookingCustomerPhoneHint,
          controller: phoneController,
          validator:
              (v) =>
                  (v == null || v.isEmpty)
                      ? context.l10n.dashboardManualBookingCustomerPhoneRequired
                      : null,
        ),
      ],
    );
  }
}

class _ServiceSelection extends StatelessWidget {
  const _ServiceSelection({
    required this.services,
    required this.selectedService,
    required this.onChanged,
  });

  final List<ServiceEntity> services;
  final ServiceEntity? selectedService;
  final ValueChanged<ServiceEntity> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StyledDropdown<ServiceEntity>(
      label: context.l10n.dashboardManualBookingSelectService,
      value: selectedService,
      items: services,
      itemLabel: (s) => '${s.name} (${s.price}€, ${s.durationMinutes}min)',
      onChanged: (s) {
        if (s != null) onChanged(s);
      },
    );
  }
}

class _BarberSelection extends StatelessWidget {
  const _BarberSelection({
    required this.barbers,
    required this.selectedBarber,
    required this.onChanged,
  });

  final List<BarberEntity> barbers;
  final BarberEntity? selectedBarber;
  final ValueChanged<BarberEntity> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StyledDropdown<BarberEntity>(
      label: context.l10n.dashboardManualBookingSelectBarber,
      value: selectedBarber,
      items: barbers,
      itemLabel: (b) => b.name,
      onChanged: (b) {
        if (b != null) onChanged(b);
      },
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.appTextStyles.h2.copyWith(
            color: context.appColors.secondaryTextColor,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          value: value,
          isExpanded: true,
          dropdownColor: context.appColors.menuBackgroundColor,
          decoration: InputDecoration(
            fillColor: context.appColors.secondaryColor,
            filled: true,
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
              borderSide: BorderSide(color: context.appColors.primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          items:
              items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel(item),
                    style: context.appTextStyles.h2.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
