import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/value_objects/working_hours.dart';
import 'package:barber/core/widgets/primary_button.dart';
import 'package:barber/core/widgets/time_picker_field.dart';

/// Generic dialog for editing working hours for locations.
/// Returns the updated WorkingHoursMap when saved, or null if cancelled.
class EditLocationWorkingHoursDialog extends HookWidget {
  const EditLocationWorkingHoursDialog({
    required this.initialHours,
    super.key,
  });

  final WorkingHoursMap? initialHours;

  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sizes = context.appSizes;
    final l10n = context.l10n;

    // Per-day enabled: superadmin can disable/activate each weekday.
    final dayEnabled = useState<List<bool>>(
      List.generate(7, (i) => initialHours?[_dayKeys[i]] != null),
    );

    // Initialize controllers with initial values
    final openControllers = useMemoized(() {
      return List.generate(7, (i) {
        final dayHours = initialHours?[_dayKeys[i]];
        return TextEditingController(text: dayHours?.open ?? '');
      });
    }, []);

    final closeControllers = useMemoized(() {
      return List.generate(7, (i) {
        final dayHours = initialHours?[_dayKeys[i]];
        return TextEditingController(text: dayHours?.close ?? '');
      });
    }, []);

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
      final weekday = index + 1;
      final targetDate = baseDate.add(Duration(days: weekday - 1));
      final formatted = DateFormat('EEE', locale).format(targetDate);
      return formatted.isEmpty
          ? formatted
          : formatted[0].toUpperCase() + formatted.substring(1);
    });

    void onSave() {
      final WorkingHoursMap newHours = {};

      for (var i = 0; i < 7; i++) {
        if (!dayEnabled.value[i]) {
          newHours[_dayKeys[i]] = null;
          continue;
        }
        final open = _normalizeTime(openControllers[i].text.trim());
        final close = _normalizeTime(closeControllers[i].text.trim());

        if (open.isNotEmpty && close.isNotEmpty) {
          newHours[_dayKeys[i]] = DayWorkingHours(
            open: open,
            close: close,
          );
        } else {
          newHours[_dayKeys[i]] = null;
        }
      }

      Navigator.of(context).pop(newHours);
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dashboardLocationWorkingHours,
                            style: context.appTextStyles.h3.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.workingHoursApplyHint,
                            style: context.appTextStyles.h4.copyWith(
                              color: colors.captionTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: colors.secondaryTextColor),
                    ),
                  ],
                ),
                Gap(sizes.paddingMedium),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(7, (i) {
                        return _WorkingHoursRow(
                          dayLabel: dayLabels[i],
                          enabled: dayEnabled.value[i],
                          onEnabledChanged: (v) {
                            final next = List<bool>.from(dayEnabled.value);
                            next[i] = v;
                            dayEnabled.value = next;
                          },
                          openController: openControllers[i],
                          closeController: closeControllers[i],
                        );
                      }),
                    ),
                  ),
                ),
                Gap(sizes.paddingMedium),
                PrimaryButton.big(
                  onPressed: onSave,
                  child: Text(l10n.applyChanges),
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
    required this.enabled,
    required this.onEnabledChanged,
    required this.openController,
    required this.closeController,
  });

  final String dayLabel;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
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
            width: 44,
            child: Text(
              dayLabel,
              style: context.appTextStyles.medium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color:
                    enabled
                        ? colors.secondaryTextColor
                        : colors.secondaryTextColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          Gap(sizes.paddingSmall),
          Switch.adaptive(
            value: enabled,
            onChanged: onEnabledChanged,
            activeColor: colors.primaryColor,
          ),
          Gap(sizes.paddingSmall),
          Expanded(
            child: IgnorePointer(
              ignoring: !enabled,
              child: Opacity(
                opacity: enabled ? 1 : 0.5,
                child: TimePickerField(
                  controller: openController,
                  hintText: '09:00',
                  fillColor: colors.menuBackgroundColor,
                ),
              ),
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
            child: IgnorePointer(
              ignoring: !enabled,
              child: Opacity(
                opacity: enabled ? 1 : 0.5,
                child: TimePickerField(
                  controller: closeController,
                  hintText: '17:00',
                  fillColor: colors.menuBackgroundColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
