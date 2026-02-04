import 'package:flutter/services.dart';

/// Formatter for HH:mm time input (e.g. 14:00, 09:30).
/// Limits input to 5 chars, auto-inserts colon after 2 digits.
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.length > 4) {
      return oldValue;
    }
    String formatted;
    if (text.length <= 2) {
      formatted = text;
    } else {
      formatted = '${text.substring(0, 2)}:${text.substring(2)}';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Validates HH:mm format. Returns null if valid, error message if invalid.
String? validateTimeFormat(String? value, {String? formatError}) {
  if (value == null || value.trim().isEmpty) return null;
  if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value.trim())) {
    return formatError ?? 'Use HH:mm (e.g. 14:00)';
  }
  final parts = value.trim().split(':');
  final h = int.tryParse(parts[0]) ?? -1;
  final m = int.tryParse(parts[1]) ?? -1;
  if (h < 0 || h > 23 || m < 0 || m > 59) {
    return 'Invalid time';
  }
  return null;
}

/// Parses HH:mm to minutes since midnight. Returns null if invalid.
int? _parseToMinutes(String value) {
  if (!RegExp(r'^\d{1,2}:\d{2}$').hasMatch(value)) return null;
  final parts = value.split(':');
  final h = int.tryParse(parts[0]) ?? -1;
  final m = int.tryParse(parts[1]) ?? -1;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}

/// Validates that start < end. Returns error message if start >= end.
String? validateStartBeforeEnd(
  String? start,
  String? end, {
  String? errorMessage,
}) {
  if (start == null || end == null) return null;
  if (start.trim().isEmpty || end.trim().isEmpty) return null;
  final startMin = _parseToMinutes(start.trim());
  final endMin = _parseToMinutes(end.trim());
  if (startMin == null || endMin == null) return null;
  if (startMin >= endMin) {
    return errorMessage ?? 'Start must be before end';
  }
  return null;
}
