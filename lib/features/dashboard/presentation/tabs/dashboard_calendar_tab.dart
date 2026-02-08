import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';

import 'package:barber/features/auth/di.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

/// Modern day-view calendar tab optimized for barber appointments.
class DashboardCalendarTab extends HookConsumerWidget {
  const DashboardCalendarTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(barberUpcomingAppointmentsProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final homeState = ref.watch(homeNotifierProvider);
    final locations =
        homeState is BaseData<HomeData>
            ? homeState.data.locations
            : <LocationEntity>[];
    final brand = homeState is BaseData<HomeData> ? homeState.data.brand : null;

    final selectedDate = useState(DateTime.now());

    return appointmentsAsync.when(
      data: (appointments) {
        final dayAppointments = _getAppointmentsForDay(
          appointments,
          selectedDate.value,
        );

        return Column(
          children: [
            _CalendarHeader(
              selectedDate: selectedDate.value,
              onDateChanged: (date) => selectedDate.value = date,
              appointmentCount: dayAppointments.length,
            ),
            Expanded(
              child: _DayTimelineView(
                selectedDate: selectedDate.value,
                appointments: dayAppointments,
                locations: locations,
                slotInterval: brand?.slotInterval ?? 15,
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Text(
              context.l10n.errorLoadingAppointments,
              style: context.appTextStyles.medium,
            ),
          ),
    );
  }

  static List<AppointmentEntity> _getAppointmentsForDay(
    List<AppointmentEntity> appointments,
    DateTime day,
  ) {
    final filtered =
        appointments.where((appointment) {
          final appointmentDate = appointment.startTime;
          return appointmentDate.year == day.year &&
              appointmentDate.month == day.month &&
              appointmentDate.day == day.day;
        }).toList();

    filtered.sort((a, b) => a.startTime.compareTo(b.startTime));
    return filtered;
  }
}

/// Compact calendar header with date selector.
class _CalendarHeader extends HookWidget {
  const _CalendarHeader({
    required this.selectedDate,
    required this.onDateChanged,
    required this.appointmentCount,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final int appointmentCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      padding: EdgeInsets.all(context.appSizes.paddingMedium),
      decoration: BoxDecoration(
        color: colors.menuBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: colors.borderColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DateSelector(
              selectedDate: selectedDate,
              onDateChanged: onDateChanged,
              locale: locale,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$appointmentCount',
              style: context.appTextStyles.medium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Date selector with navigation.
class _DateSelector extends HookWidget {
  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
    required this.locale,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dateFormat = DateFormat('EEEE, MMM d', locale);
    final dateStr = dateFormat.format(selectedDate);
    final isToday = _isToday(selectedDate);

    return Row(
      children: [
        IconButton(
          onPressed: () {
            onDateChanged(selectedDate.subtract(const Duration(days: 1)));
          },
          icon: Icon(
            Icons.chevron_left,
            color: colors.primaryTextColor,
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.dark(
                        primary: colors.primaryColor,
                        onPrimary: colors.primaryWhiteColor,
                        surface: colors.menuBackgroundColor,
                        onSurface: colors.primaryTextColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                onDateChanged(picked);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  dateStr,
                  style: context.appTextStyles.h2.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (isToday)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      context.l10n.calendarToday,
                      style: context.appTextStyles.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            onDateChanged(selectedDate.add(const Duration(days: 1)));
          },
          icon: Icon(
            Icons.chevron_right,
            color: colors.primaryTextColor,
          ),
        ),
      ],
    );
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

/// Day timeline view with dynamic grid based on slot interval.
class _DayTimelineView extends HookWidget {
  const _DayTimelineView({
    required this.selectedDate,
    required this.appointments,
    required this.locations,
    required this.slotInterval,
  });

  final DateTime selectedDate;
  final List<AppointmentEntity> appointments;
  final List<LocationEntity> locations;
  final int slotInterval;

  // Adjusted to show approx 6 hours on screen
  static const double hourHeight = 100.0;
  static const int startHour = 8;
  static const int endHour = 20;
  static const double timeColumnWidth = 50.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scrollController = useScrollController();

    // Auto-scroll to current time or first appointment
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final now = DateTime.now();
        double scrollOffset;

        if (_isToday(selectedDate) &&
            now.hour >= startHour &&
            now.hour <= endHour) {
          // Scroll to current time
          final currentHour = now.hour + (now.minute / 60);
          scrollOffset = (currentHour - startHour) * hourHeight - 100;
        } else if (appointments.isNotEmpty) {
          // Scroll to first appointment
          final firstAppt = appointments.first;
          final apptHour =
              firstAppt.startTime.hour + (firstAppt.startTime.minute / 60);
          scrollOffset = (apptHour - startHour) * hourHeight - 50;
        } else {
          scrollOffset = 0;
        }

        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollOffset.clamp(
              0,
              scrollController.position.maxScrollExtent,
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      return null;
    }, [selectedDate]);

    return Container(
      color: colors.backgroundColor,
      child: SingleChildScrollView(
        controller: scrollController,
        child: SizedBox(
          height: (endHour - startHour) * hourHeight,
          child: Stack(
            children: [
              // Hour grid with dynamic slot lines
              _HourGrid(
                startHour: startHour,
                endHour: endHour,
                hourHeight: hourHeight,
                timeColumnWidth: timeColumnWidth,
                slotInterval: slotInterval,
              ),
              // Appointments
              Positioned(
                left: timeColumnWidth,
                right: 0,
                top: 0,
                bottom: 0,
                child: Stack(
                  children: [
                    ...appointments.map((appointment) {
                      return _AppointmentBlock(
                        appointment: appointment,
                        startHour: startHour,
                        hourHeight: hourHeight,
                        locationName: _getLocationName(
                          locations,
                          appointment.locationId,
                        ),
                      );
                    }),
                    // Current time indicator
                    if (_isToday(selectedDate))
                      _CurrentTimeIndicator(
                        startHour: startHour,
                        hourHeight: hourHeight,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static String? _getLocationName(
    List<LocationEntity> locations,
    String locationId,
  ) {
    try {
      return locations.firstWhere((l) => l.locationId == locationId).name;
    } catch (_) {
      return null;
    }
  }
}

/// Hour grid with dynamic slot lines based on interval.
class _HourGrid extends StatelessWidget {
  const _HourGrid({
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.timeColumnWidth,
    required this.slotInterval,
  });

  final int startHour;
  final int endHour;
  final double hourHeight;
  final double timeColumnWidth;
  final int slotInterval;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      children: List.generate(
        endHour - startHour,
        (index) {
          final hour = startHour + index;
          return _HourSlot(
            hour: hour,
            height: hourHeight,
            timeColumnWidth: timeColumnWidth,
            slotInterval: slotInterval,
            colors: colors,
          );
        },
      ),
    );
  }
}

/// Hour slot with dynamic interval lines.
class _HourSlot extends StatelessWidget {
  const _HourSlot({
    required this.hour,
    required this.height,
    required this.timeColumnWidth,
    required this.slotInterval,
    required this.colors,
  });

  final int hour;
  final double height;
  final double timeColumnWidth;
  final int slotInterval;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final timeStr = DateFormat.j(locale).format(
      DateTime(2000, 1, 1, hour),
    );

    // Calculate number of slot lines per hour
    final slotsPerHour = 60 ~/ slotInterval;
    final slotHeight = height / slotsPerHour;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Time label at top
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: timeColumnWidth,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 2),
                  child: Text(
                    timeStr,
                    style: context.appTextStyles.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: colors.captionTextColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ],
          ),
          // Slot interval lines
          ...List.generate(slotsPerHour, (index) {
            // Smart grid color: mix secondary text with a bit of primary for brand feel, but keep high contrast
            final baseGridColor =
                Color.lerp(
                  colors.secondaryTextColor,
                  colors.primaryColor,
                  0.15,
                )!;

            final isHourLine = index == 0;

            return Positioned(
              left: timeColumnWidth,
              right: 0,
              top: index * slotHeight,
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color:
                          isHourLine
                              ? baseGridColor.withValues(alpha: 0.4)
                              : baseGridColor.withValues(alpha: 0.1),
                      width: isHourLine ? 1.5 : 1,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Current time indicator.
class _CurrentTimeIndicator extends HookWidget {
  const _CurrentTimeIndicator({
    required this.startHour,
    required this.hourHeight,
  });

  final int startHour;
  final double hourHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    if (currentHour < startHour) return const SizedBox.shrink();

    final hoursFromStart = currentHour - startHour;
    final minuteOffset = (currentMinute / 60) * hourHeight;
    final topPosition = (hoursFromStart * hourHeight) + minuteOffset;

    return Positioned(
      left: 0,
      right: 0,
      top: topPosition,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.errorColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.errorColor,
                    colors.errorColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Appointment block optimized for small durations.
class _AppointmentBlock extends HookWidget {
  const _AppointmentBlock({
    required this.appointment,
    required this.startHour,
    required this.hourHeight,
    this.locationName,
  });

  final AppointmentEntity appointment;
  final int startHour;
  final double hourHeight;
  final String? locationName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final locale = Localizations.localeOf(context).languageCode;

    final startTime = appointment.startTime;
    final endTime = appointment.endTime;
    final duration = endTime.difference(startTime);

    // Calculate position
    final startHourDecimal = startTime.hour + (startTime.minute / 60);
    final durationHours = duration.inMinutes / 60;
    final topPosition = (startHourDecimal - startHour) * hourHeight;
    final blockHeight = (durationHours * hourHeight).clamp(
      25.0,
      double.infinity,
    );

    final timeFormat = DateFormat.Hm(locale);
    final startTimeStr = timeFormat.format(startTime);
    final endTimeStr = timeFormat.format(endTime);

    final blockColor = _getAppointmentColor(appointment);

    return Positioned(
      left: 0,
      right: 0,
      top: topPosition,
      height: blockHeight,
      child: _AppointmentBlockContent(
        appointment: appointment,
        startTimeStr: startTimeStr,
        endTimeStr: endTimeStr,
        blockColor: blockColor,
        colors: colors,
        isSmall: duration.inMinutes <= 15,
      ),
    );
  }

  static Color _getAppointmentColor(AppointmentEntity appointment) {
    // Generate color based on user ID for consistency
    final hash = appointment.userId.hashCode;
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.65, 0.55).toColor();
  }
}

/// Appointment block content with adaptive layout.
class _AppointmentBlockContent extends HookWidget {
  const _AppointmentBlockContent({
    required this.appointment,
    required this.startTimeStr,
    required this.endTimeStr,
    required this.blockColor,
    required this.colors,
    required this.isSmall,
  });

  final AppointmentEntity appointment;
  final String startTimeStr;
  final String endTimeStr;
  final Color blockColor;
  final AppColors colors;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    final isPressed = useState(false);
    final duration = appointment.endTime.difference(appointment.startTime);

    return GestureDetector(
      onTapDown: (_) => isPressed.value = true,
      onTapUp: (_) => isPressed.value = false,
      onTapCancel: () => isPressed.value = false,
      onTap:
          () => context.push(
            AppRoute.manageBooking.path.replaceFirst(
              ':appointmentId',
              appointment.appointmentId,
            ),
          ),
      child: AnimatedScale(
        scale: isPressed.value ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: duration.inMinutes <= 30 ? 2 : 8,
          ),
          decoration: BoxDecoration(
            color: blockColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: blockColor.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child:
              isSmall
                  ? _SmallAppointmentLayout(
                    appointment: appointment,
                    startTimeStr: startTimeStr,
                    endTimeStr: endTimeStr,
                  )
                  : _LargeAppointmentLayout(
                    appointment: appointment,
                    startTimeStr: startTimeStr,
                    endTimeStr: endTimeStr,
                  ),
        ),
      ),
    );
  }
}

/// Layout for small appointments (≤30 min) - single line.
class _SmallAppointmentLayout extends StatelessWidget {
  const _SmallAppointmentLayout({
    required this.appointment,
    required this.startTimeStr,
    required this.endTimeStr,
  });

  final AppointmentEntity appointment;
  final String startTimeStr;
  final String endTimeStr;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${appointment.customerName} • ${appointment.serviceName}',
            style: context.appTextStyles.medium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Gap(4),
        Text(
          '$startTimeStr-$endTimeStr',
          style: context.appTextStyles.caption.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// Layout for larger appointments (>30 min).
class _LargeAppointmentLayout extends StatelessWidget {
  const _LargeAppointmentLayout({
    required this.appointment,
    required this.startTimeStr,
    required this.endTimeStr,
  });

  final AppointmentEntity appointment;
  final String startTimeStr;
  final String endTimeStr;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$startTimeStr - $endTimeStr',
          style: context.appTextStyles.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.1,
          ),
        ),
        Gap(4),
        Text(
          appointment.customerName,
          style: context.appTextStyles.h2.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Gap(4),
        Text(
          appointment.serviceName,
          style: context.appTextStyles.medium.copyWith(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
