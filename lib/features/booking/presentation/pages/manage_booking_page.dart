import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/widgets/custom_app_bar.dart';
import 'package:barber/features/booking/di.dart';
import 'package:barber/features/booking/presentation/bloc/manage_booking_notifier.dart';
import 'package:barber/features/barbers/di.dart';
import 'package:barber/features/booking/presentation/widgets/manage_booking_actions.dart';
import 'package:barber/features/booking/presentation/widgets/manage_booking_detail_card.dart';
import 'package:barber/features/booking/presentation/widgets/manage_booking_shimmer.dart';
import 'package:barber/features/booking/presentation/bloc/appointment_action_notifier.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/auth/di.dart';

class ManageBookingPage extends ConsumerWidget {
  const ManageBookingPage({
    super.key,
    required this.appointmentId,
  });

  final String appointmentId;

  static const _horizontalPadding = 20.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(manageBookingNotifierProvider(appointmentId));
    final isBarberView = ref.watch(isStaffProvider);
    final notifier = ref.read(
      manageBookingNotifierProvider(appointmentId).notifier,
    );

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: CustomAppBar.withTitleAndBackButton(
        context.l10n.manageBookingTitle,
        onBack: () => context.go(AppRoute.home.path),
      ),
      body: switch (state) {
        BaseError() => _ManageBookingError(message: state.message),
        BaseData(:final data) => _ManageBookingBody(
          data: data,
          notifier: notifier,
          canEdit: !isBarberView,
          onCancelSuccess: (ctx, r) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(ctx.l10n.manageBookingCanceledSnackbar)),
            );
            r.invalidate(upcomingAppointmentProvider);
            ctx.go(AppRoute.home.path);
          },
        ),
        _ => const _ManageBookingLoading(),
      },
    );
  }
}

typedef _OnCancelSuccess = void Function(BuildContext context, WidgetRef ref);

class _ManageBookingBody extends ConsumerStatefulWidget {
  const _ManageBookingBody({
    required this.data,
    required this.notifier,
    required this.canEdit,
    required this.onCancelSuccess,
  });

  final ManageBookingData data;
  final ManageBookingNotifier notifier;
  final bool canEdit;
  final _OnCancelSuccess onCancelSuccess;

  @override
  ConsumerState<_ManageBookingBody> createState() => _ManageBookingBodyState();
}

class _ManageBookingBodyState extends ConsumerState<_ManageBookingBody> {
  bool _isCancelling = false;

  Future<void> _handleCancelTap() async {
    final confirmed = await _showCancelConfirmation();
    if (!confirmed || !mounted) return;

    setState(() => _isCancelling = true);
    final success = await widget.notifier.cancel();
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (success && mounted) {
      widget.onCancelSuccess(context, ref);
    }
  }

  Future<bool> _showCancelConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => _CancelConfirmationDialog(
            onConfirm: () => Navigator.of(ctx).pop(true),
            onDismiss: () => Navigator.of(ctx).pop(false),
          ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: ManageBookingPage._horizontalPadding,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ManageBookingDetailCard(
            data: widget.data,
            isProfessionalView: !widget.canEdit,
          ),
          Gap(context.appSizes.paddingLarge),
          ManageBookingActions(
            onCancel: _handleCancelTap,
            appointmentId: widget.data.appointment.appointmentId,
            isCancelling: _isCancelling,
            canCancel: widget.data.canCancel || !widget.canEdit,
            canEdit: widget.canEdit,
          ),
          if (!widget.canEdit) ...[
            Gap(context.appSizes.paddingLarge),
            _BarberActionButtons(appointment: widget.data.appointment),
          ],
          Gap(context.appSizes.paddingXxl),
        ],
      ),
    );

    if (kIsWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: content,
        ),
      );
    }

    return content;
  }
}

class _BarberActionButtons extends ConsumerWidget {
  const _BarberActionButtons({required this.appointment});

  final AppointmentEntity appointment;

  Future<void> _handleComplete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(ctx.l10n.completeAppointmentTitle),
            content: Text(ctx.l10n.completeAppointmentMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(ctx.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(ctx.l10n.complete),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(appointmentActionNotifierProvider.notifier)
          .markAsComplete(appointment.appointmentId, appointment.userId);

      if (success && context.mounted) {
        ref.invalidate(upcomingAppointmentProvider);
        ref.invalidate(
          manageBookingNotifierProvider(appointment.appointmentId),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.appointmentCompleted)),
        );

        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoute.home.path);
        }
      }
    }
  }

  Future<void> _handleNoShow(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(ctx.l10n.markAsNoShowTitle),
            content: Text(ctx.l10n.markAsNoShowMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(ctx.l10n.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: ctx.appColors.errorColor,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(ctx.l10n.noShow),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(appointmentActionNotifierProvider.notifier)
          .markAsNoShow(appointment.appointmentId, appointment.userId);

      if (success && context.mounted) {
        ref.invalidate(upcomingAppointmentProvider);
        ref.invalidate(
          manageBookingNotifierProvider(appointment.appointmentId),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.appointmentMarkedAsNoShow)),
        );

        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoute.home.path);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (appointment.status != AppointmentStatus.scheduled) {
      return const SizedBox.shrink();
    }
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => _handleComplete(context, ref),
            style: FilledButton.styleFrom(
              backgroundColor: colors.successColor,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.check),
            label: Text(context.l10n.complete),
          ),
          Gap(context.appSizes.paddingMedium),
          OutlinedButton.icon(
            onPressed: () => _handleNoShow(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.errorColor,
              side: BorderSide(color: colors.errorColor),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.person_off_rounded),
            label: Text(context.l10n.noShow),
          ),
        ],
      ),
    );
  }
}

class _CancelConfirmationDialog extends StatelessWidget {
  const _CancelConfirmationDialog({
    required this.onConfirm,
    required this.onDismiss,
  });

  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sizes = context.appSizes;
    final overlayColor = colors.primaryColor.withValues(alpha: 0.12);
    return AlertDialog(
      backgroundColor: colors.secondaryColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(sizes.borderRadius * 1.5),
        side: BorderSide(
          color: colors.borderColor.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      title: Text(
        context.l10n.manageBookingCancelConfirmTitle,
        style: context.appTextStyles.h1.copyWith(
          fontSize: 20,
          color: colors.primaryTextColor,
        ),
      ),
      content: Text(
        context.l10n.manageBookingCancelConfirmMessage,
        style: context.appTextStyles.body.copyWith(
          color: colors.secondaryTextColor,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          style: TextButton.styleFrom(
            foregroundColor: colors.captionTextColor,
            overlayColor: overlayColor,
          ),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(
            foregroundColor: colors.errorColor,
            overlayColor: overlayColor,
          ),
          child: Text(
            context.l10n.manageBookingCancelConfirm,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ManageBookingLoading extends StatelessWidget {
  const _ManageBookingLoading();

  @override
  Widget build(BuildContext context) {
    return const ManageBookingShimmer();
  }
}

class _ManageBookingError extends StatelessWidget {
  const _ManageBookingError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: colors.errorColor,
              ),
              Gap(context.appSizes.paddingMedium),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: 14,
                ),
              ),
              Gap(context.appSizes.paddingMedium),
              TextButton.icon(
                onPressed: () => context.go(AppRoute.home.path),
                icon: Icon(Icons.home_rounded, color: colors.primaryColor),
                label: Text(
                  context.l10n.navHome,
                  style: TextStyle(color: colors.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
