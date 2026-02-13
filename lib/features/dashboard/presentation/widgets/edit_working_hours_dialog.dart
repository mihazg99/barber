import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/core/widgets/time_picker_field.dart';
import 'package:barber/features/barbers/di.dart' as barbers_di;
import 'package:barber/features/dashboard/di.dart';

class EditWorkingHoursDialog extends HookConsumerWidget {
  const EditWorkingHoursDialog({super.key});

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final sizes = context.appSizes;
    final l10n = context.l10n;

    // We need the current barber to save updates
    final barberAsync = ref.watch(currentBarberProvider);
    // We need effective hours to pre-fill the form
    final effectiveHoursAsync = ref.watch(barberEffectiveWorkingHoursProvider);

    final isLoading = useState(false);
    final isInitialized = useRef(false);

    // Initialize controllers only once - don't recreate on data changes
    final openControllers = useMemoized(() {
      return List.generate(7, (_) => TextEditingController());
    }, []);

    final closeControllers = useMemoized(() {
      return List.generate(7, (_) => TextEditingController());
    }, []);

    // Initialize controller values only once when data first loads
    useEffect(() {
      final hours = effectiveHoursAsync.asData?.value;
      if (hours != null && !isInitialized.value) {
        for (var i = 0; i < 7; i++) {
          openControllers[i].text = hours[_dayKeys[i]]?.open ?? '';
          closeControllers[i].text = hours[_dayKeys[i]]?.close ?? '';
        }
        isInitialized.value = true;
      }
      return null;
    }, [effectiveHoursAsync.asData?.value]);

    // Dispose controllers
    useEffect(() {
      return () {
        for (final c in openControllers) c.dispose();
        for (final c in closeControllers) c.dispose();
      };
    }, []);

    // Get localized weekday abbreviations
    final locale = Localizations.localeOf(context).toString();
    final baseDate = DateTime(2024, 1, 1); // Monday
    final dayLabels = List.generate(7, (index) {
      final weekday = index + 1; // Convert 0-6 index to 1-7 weekday
      final targetDate = baseDate.add(Duration(days: weekday - 1));
      final formatted = DateFormat('EEE', locale).format(targetDate);
      // Capitalize first letter
      return formatted.isEmpty ? formatted : formatted[0].toUpperCase() + formatted.substring(1);
    });

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
            // Invalidate providers to refresh the UI
            ref.invalidate(currentBarberProvider);
            ref.invalidate(barberEffectiveWorkingHoursProvider);
            
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

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Material(
        color: colors.menuBackgroundColor,
        child: Container(
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
                    style: context.appTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colors.secondaryTextColor),
                  ),
                ],
              ),
              Gap(sizes.paddingMedium),
              if (barberAsync.isLoading || effectiveHoursAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: CircularProgressIndicator()),
                )
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
                loading: isLoading.value,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
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
            width: 50,
            child: Text(
              dayLabel,
              style: context.appTextStyles.medium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: colors.secondaryTextColor,
              ),
            ),
          ),
          Gap(sizes.paddingSmall),
          Expanded(
            child: TimePickerField(
              controller: openController,
              hintText: '09:00',
              fillColor: colors.menuBackgroundColor,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sizes.paddingSmall),
            child: Text(
              '–',
              style: context.appTextStyles.medium.copyWith(
                color: colors.captionTextColor,
                fontSize: 18,
              ),
            ),
          ),
          Expanded(
            child: TimePickerField(
              controller: closeController,
              hintText: '17:00',
              fillColor: colors.menuBackgroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
