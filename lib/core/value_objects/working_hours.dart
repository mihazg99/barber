/// Working hours for a single day (e.g. mon, tue).
/// Use null for closed days. Shared across locations and barbers features.
class DayWorkingHours {
  const DayWorkingHours({
    required this.open,
    required this.close,
  });

  final String open; // e.g. "08:00"
  final String close; // e.g. "20:00"

  Map<String, String> toMap() => {'open': open, 'close': close};

  static DayWorkingHours? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final open = map['open'] as String?;
    final close = map['close'] as String?;
    if (open == null || close == null) return null;
    return DayWorkingHours(open: open, close: close);
  }
}

/// Keys: mon, tue, wed, thu, fri, sat, sun. Value null = closed.
typedef WorkingHoursMap = Map<String, DayWorkingHours?>;
