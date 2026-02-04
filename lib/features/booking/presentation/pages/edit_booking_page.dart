import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/widgets/custom_app_bar.dart';
import 'package:barber/features/booking/di.dart';
import 'package:barber/features/booking/domain/entities/time_slot.dart';
import 'package:barber/features/booking/presentation/widgets/booking_date_section.dart';
import 'package:barber/features/booking/presentation/widgets/booking_time_section.dart';
import 'package:barber/features/booking/presentation/widgets/edit_booking_footer.dart';
import 'package:barber/features/booking/presentation/widgets/edit_booking_summary_card.dart';
import 'package:barber/features/home/di.dart';

class EditBookingPage extends ConsumerStatefulWidget {
  const EditBookingPage({
    super.key,
    required this.appointmentId,
  });

  final String appointmentId;

  @override
  ConsumerState<EditBookingPage> createState() => _EditBookingPageState();
}

class _EditBookingPageState extends ConsumerState<EditBookingPage> {
  bool _isConfirming = false;
  List<TimeSlot>? _lastTimeSlots;

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(
      editBookingNotifierProvider(widget.appointmentId),
    );
    final timeSlotsAsync = ref.watch(
      availableTimeSlotsForEditProvider(widget.appointmentId),
    );

    ref.listen(availableTimeSlotsForEditProvider(widget.appointmentId), (
      prev,
      next,
    ) {
      next.whenData((slots) {
        if (mounted && slots.isNotEmpty) {
          setState(() => _lastTimeSlots = slots);
        }
      });
    });

    if (editState == null) {
      return Scaffold(
        backgroundColor: context.appColors.backgroundColor,
        appBar: CustomAppBar.withTitleAndBackButton(
          context.l10n.editBookingTitle,
          onBack: () => context.pop(),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: CustomAppBar.withTitleAndBackButton(
        context.l10n.editBookingTitle,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: context.appSizes.paddingMedium,
                horizontal: context.appSizes.paddingMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EditBookingSummaryCard(state: editState),
                  Gap(context.appSizes.paddingLarge),
                  BookingDateSection(
                    title: context.l10n.editBookingSelectNewDate,
                    selectedDate: editState.selectedDate,
                    onDateSelected: (date) {
                      ref
                          .read(
                            editBookingNotifierProvider(
                              widget.appointmentId,
                            ).notifier,
                          )
                          .selectDate(date);
                    },
                  ),
                  Gap(context.appSizes.paddingLarge),
                  BookingTimeSection(
                    title: context.l10n.editBookingSelectNewTime,
                    timeSlots:
                        timeSlotsAsync.isLoading
                            ? (_lastTimeSlots ?? [])
                            : (timeSlotsAsync.valueOrNull ?? []),
                    selectedTimeSlot: editState.selectedTimeSlot,
                    onTimeSlotSelected: (slot) {
                      ref
                          .read(
                            editBookingNotifierProvider(
                              widget.appointmentId,
                            ).notifier,
                          )
                          .selectTimeSlot(slot);
                    },
                    isLoading: timeSlotsAsync.isLoading,
                  ),
                  Gap(context.appSizes.paddingXxl),
                ],
              ),
            ),
          ),
          EditBookingFooter(
            canConfirm: editState.canConfirm,
            onConfirm: _confirmReschedule,
            isConfirming: _isConfirming,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReschedule() async {
    setState(() => _isConfirming = true);
    final success =
        await ref
            .read(editBookingNotifierProvider(widget.appointmentId).notifier)
            .reschedule();
    if (!mounted) return;
    setState(() => _isConfirming = false);

    if (success) {
      ref.invalidate(upcomingAppointmentProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.editBookingSuccessSnackbar)),
      );
      context.go(AppRoute.home.path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.editBookingErrorSnackbar),
          backgroundColor: context.appColors.errorColor,
        ),
      );
    }
  }
}
