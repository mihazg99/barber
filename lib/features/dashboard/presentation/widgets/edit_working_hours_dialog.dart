import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/core/utils/time_input_formatter.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/features/barbers/di.dart' as barbers_di;
import 'package:barber/features/dashboard/di.dart';

class EditWorkingHoursDialog extends HookConsumerWidget {
  const EditWorkingHoursDialog({super.key});

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizes = context.appSizes;
    final l10n = context.l10n;

    // We need the current barber to save updates
    final barberAsync = ref.watch(currentBarberProvider);
    // We need effective hours to pre-fill the form
    final effectiveHoursAsync = ref.watch(barberEffectiveWorkingHoursProvider);

    final isLoading = useState(false);

    // Initialize controllers with effective hours (or empty if none)
    final openControllers = useMemoized(() {
      final hours = effectiveHoursAsync.asData?.value;
      return List.generate(7, (i) {
        final val = hours?[_dayKeys[i]]?.open ?? '';
        return TextEditingController(text: val);
      });
    }, [effectiveHoursAsync.asData?.value]);

    final closeControllers = useMemoized(() {
      final hours = effectiveHoursAsync.asData?.value;
      return List.generate(7, (i) {
        final val = hours?[_dayKeys[i]]?.close ?? '';
        return TextEditingController(text: val);
      });
    }, [effectiveHoursAsync.asData?.value]);

    // Dispose controllers
    useEffect(() {
      return () {
        for (final c in openControllers) c.dispose();
        for (final c in closeControllers) c.dispose();
      };
    }, []);

    // Simple day labels for now (matching WorkingHoursCard)
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    Future<void> onSave() async {
      final barber = barberAsync.valueOrNull;
      if (barber == null) return;

      isLoading.value = true;

      try {
        final WorkingHoursMap newOverride = {};

        for (var i = 0; i < 7; i++) {
          final open = _normalizeTime(openControllers[i].text.trim());
          final close = _normalizeTime(closeControllers[i].text.trim());

          if (open.isNotEmpty || close.isNotEmpty) {
            // If one is filled, try to use it. Validation should ideally happen before save.
            // For now, if partial, we save what we have or treat as closed if invalid?
            // Logic from barber_form_page: if open && close are not empty -> DayWorkingHours.
            // Else -> null (closed).
            if (open.isNotEmpty && close.isNotEmpty) {
              newOverride[_dayKeys[i]] = DayWorkingHours(
                open: open,
                close: close,
              );
            } else {
              newOverride[_dayKeys[i]] = null;
            }
          } else {
            // Explicitly set to null (closed) for this day in the override
            newOverride[_dayKeys[i]] = null;
          }
        }

        // If ALL fields are empty, we might want to clear the override entirely?
        // But here we are editing "active" hours. The user intention "I want these hours".
        // If they clear everything, they probably want to be closed or reset.
        // Let's assume if they save, they are setting an override.
        // Special case: if hasAnyHours is false, maybe they want to reset to default?
        // Or maybe they want to be closed all week.
        // Current logic creates an override map where days are null (closed).

        // If the map is completely empty of working days (all null), that's a valid override (closed all week).
        // If we want to "reset to default", we'd need a separate "Reset" button.

        final updatedBarber = barber.copyWith(
          workingHoursOverride: newOverride,
        );

        final repo = ref.read(barbers_di.barberRepositoryProvider);
        final result = await repo.set(updatedBarber);

        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving: ${failure.toString()}')),
            );
          },
          (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.shiftWorkingHoursSaved)),
            );
            Navigator.of(context).pop();
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        isLoading.value = false;
      }
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: EdgeInsets.all(sizes.paddingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.shiftEditWorkingHours,
                  style: context.appTextStyles.h3,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Gap(sizes.paddingMedium),
            if (barberAsync.isLoading || effectiveHoursAsync.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(7, (i) {
                      return _WorkingHoursRow(
                        dayLabel: dayLabels[i],
                        openController: openControllers[i],
                        closeController: closeControllers[i],
                      );
                    }),
                  ),
                ),
              ),
            Gap(sizes.paddingMedium),
            PrimaryButton.big(
              onPressed: isLoading.value ? null : onSave,
              // isLoading is handled inside PrimaryButton if we pass it,
              // but here we just disable onPressed.
              // Wait, PrimaryButton has loading parameter.
              loading: isLoading.value,
              child: Text(l10n.save),
            ),
            Gap(sizes.paddingMedium),
          ],
        ),
      ),
    );
  }

  String _normalizeTime(String s) {
    if (s.isEmpty) return s;
    if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(s)) return s;
    final parts = s.split(':');
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

class _WorkingHoursRow extends StatelessWidget {
  const _WorkingHoursRow({
    required this.dayLabel,
    required this.openController,
    required this.closeController,
  });

  final String dayLabel;
  final TextEditingController openController;
  final TextEditingController closeController;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sizes = context.appSizes;

    return Padding(
      padding: EdgeInsets.only(bottom: sizes.paddingSmall),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              dayLabel,
              style: context.appTextStyles.medium.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.secondaryTextColor,
              ),
            ),
          ),
          Gap(sizes.paddingSmall),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: colors.borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: sizes.paddingSmall),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: openController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '09:00',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: context.appTextStyles.medium,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        TimeInputFormatter(),
                      ],
                    ),
                  ),
                  Text('-', style: context.appTextStyles.medium),
                  Expanded(
                    child: TextField(
                      controller: closeController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '17:00',
                        isDense: true,
                        contentPadding: EdgeInsets.only(left: 8),
                      ),
                      style: context.appTextStyles.medium,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        TimeInputFormatter(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
