import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';

/// A field that displays time in HH:mm format and opens CupertinoTimePicker on tap.
/// Can be used with TextFormField for validation.
class TimePickerField extends StatelessWidget {
  const TimePickerField({
    required this.controller,
    this.hintText,
    this.onChanged,
    this.validator,
    this.fillColor,
    super.key,
  });

  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final Color? fillColor;

  /// Parses HH:mm string to TimeOfDay
  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    final parts = timeStr.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Formats TimeOfDay to HH:mm string
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final currentTime = _parseTime(controller.text) ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay? selectedTime = currentTime;
    
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => Container(
        height: 250,
        padding: const EdgeInsets.only(top: 6.0),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      final formatted = _formatTime(selectedTime!);
                      controller.text = formatted;
                      onChanged?.call(formatted);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: DateTime(
                    2000,
                    1,
                    1,
                    currentTime.hour,
                    currentTime.minute,
                  ),
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime dateTime) {
                    selectedTime = TimeOfDay(
                      hour: dateTime.hour,
                      minute: dateTime.minute,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sizes = context.appSizes;

    return GestureDetector(
      onTap: () => _showTimePicker(context),
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText ?? '09:00',
            filled: true,
            fillColor: fillColor ?? colors.menuBackgroundColor,
            contentPadding: EdgeInsets.symmetric(
              vertical: sizes.paddingSmall,
              horizontal: sizes.paddingMedium,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sizes.borderRadius),
              borderSide: BorderSide(color: colors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sizes.borderRadius),
              borderSide: BorderSide(color: colors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(sizes.borderRadius),
              borderSide: BorderSide(color: colors.primaryColor, width: 2),
            ),
            suffixIcon: Icon(
              Icons.access_time_rounded,
              size: 18,
              color: colors.secondaryTextColor.withOpacity(0.6),
            ),
          ),
          style: context.appTextStyles.medium,
        ),
      ),
    );
  }
}
