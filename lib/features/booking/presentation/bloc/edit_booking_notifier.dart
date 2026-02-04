import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/features/barbers/domain/repositories/barber_repository.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:barber/features/booking/data/services/booking_transaction.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/booking/domain/repositories/appointment_repository.dart';
import 'package:barber/features/locations/domain/repositories/location_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:barber/core/firebase/collections.dart';
import 'package:barber/features/booking/domain/entities/time_slot.dart';
import 'package:barber/features/services/domain/repositories/service_repository.dart';

/// State for the edit booking (reschedule) flow. Only date and time can change.
class EditBookingState {
  const EditBookingState({
    required this.appointment,
    this.locationName,
    this.barberName,
    this.serviceNames = const [],
    this.selectedDate,
    this.selectedTimeSlot,
    this.selectedTimeSlotBarberId,
  });

  final AppointmentEntity appointment;
  final String? locationName;
  final String? barberName;
  final List<String> serviceNames;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final String? selectedTimeSlotBarberId;

  int get serviceDurationMinutes =>
      appointment.endTime.difference(appointment.startTime).inMinutes;

  bool get canConfirm =>
      selectedDate != null &&
      selectedTimeSlot != null &&
      (selectedTimeSlot != _currentTimeSlot || selectedDate != _currentDate);

  DateTime get _currentDate => DateTime(
    appointment.startTime.year,
    appointment.startTime.month,
    appointment.startTime.day,
  );

  String get _currentTimeSlot =>
      '${appointment.startTime.hour.toString().padLeft(2, '0')}:'
      '${appointment.startTime.minute.toString().padLeft(2, '0')}';

  EditBookingState copyWith({
    String? locationName,
    String? barberName,
    List<String>? serviceNames,
    DateTime? selectedDate,
    String? selectedTimeSlot,
    String? selectedTimeSlotBarberId,
    bool clearDate = false,
    bool clearTimeSlot = false,
  }) {
    return EditBookingState(
      appointment: appointment,
      locationName: locationName ?? this.locationName,
      barberName: barberName ?? this.barberName,
      serviceNames: serviceNames ?? this.serviceNames,
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
      selectedTimeSlot:
          clearTimeSlot ? null : (selectedTimeSlot ?? this.selectedTimeSlot),
      selectedTimeSlotBarberId:
          clearTimeSlot
              ? null
              : (selectedTimeSlotBarberId ?? this.selectedTimeSlotBarberId),
    );
  }
}

/// Notifier for edit booking (reschedule) flow. Loads appointment, manages
/// date/time selection, and performs reschedule (cancel + create).
class EditBookingNotifier extends StateNotifier<EditBookingState?> {
  EditBookingNotifier(
    this._firestore,
    this._appointmentRepository,
    this._locationRepository,
    this._barberRepository,
    this._serviceRepository,
    this._brandRepository,
    this._bookingTransaction,
  ) : super(null);

  final FirebaseFirestore _firestore;
  final AppointmentRepository _appointmentRepository;
  final LocationRepository _locationRepository;
  final BarberRepository _barberRepository;
  final ServiceRepository _serviceRepository;
  final BrandRepository _brandRepository;
  final BookingTransaction _bookingTransaction;

  /// Loads appointment and display data from Firebase.
  Future<void> load(String appointmentId) async {
    state = null;
    final apptResult = await _appointmentRepository.getById(appointmentId);
    await apptResult.fold(
      (_) async => state = null,
      (appointment) async {
        final appt = appointment;
        if (appt == null) {
          state = null;
          return;
        }

        final locationResult = await _locationRepository.getById(
          appt.locationId,
        );
        final barberResult = await _barberRepository.getById(appt.barberId);
        var serviceNames = <String>[];
        for (final sid in appt.serviceIds) {
          final sr = await _serviceRepository.getById(sid);
          sr.fold(
            (_) => null,
            (s) => s != null ? serviceNames.add(s.name) : null,
          );
        }
        if (serviceNames.isEmpty) {
          serviceNames =
              appt.serviceIds.map((id) => 'Service ($id)').toList();
        }

        final locationName = locationResult.fold(
          (_) => 'Unknown',
          (l) => l?.name ?? 'Unknown',
        );
        final barberName = barberResult.fold(
          (_) => 'Unknown',
          (b) => b?.name ?? 'Unknown',
        );

        final currentDate = DateTime(
          appt.startTime.year,
          appt.startTime.month,
          appt.startTime.day,
        );
        final currentTime =
            '${appt.startTime.hour.toString().padLeft(2, '0')}:'
            '${appt.startTime.minute.toString().padLeft(2, '0')}';

        state = EditBookingState(
          appointment: appt,
          locationName: locationName,
          barberName: barberName,
          serviceNames: serviceNames,
          selectedDate: currentDate,
          selectedTimeSlot: currentTime,
          selectedTimeSlotBarberId: appt.barberId,
        );
      },
    );
  }

  void selectDate(DateTime date) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(
      selectedDate: date,
      clearTimeSlot: true,
      selectedTimeSlotBarberId: null,
    );
  }

  void selectTimeSlot(TimeSlot slot) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(
      selectedTimeSlot: slot.time,
      selectedTimeSlotBarberId: slot.barberId,
    );
  }

  /// Reschedules: cancels old appointment, creates new with same details
  /// but new date/time. Returns true on success.
  Future<bool> reschedule() async {
    final s = state;
    if (s == null || !s.canConfirm) return false;

    final brandResult = await _brandRepository.getById(s.appointment.brandId);
    final brand = brandResult.fold((_) => null, (b) => b);
    final cancelHoursMinimum = brand?.cancelHoursMinimum ?? 0;

    final cancelResult = await _bookingTransaction.cancelAppointment(
      s.appointment,
      cancelHoursMinimum: cancelHoursMinimum,
    );
    if (cancelResult.isLeft()) return false;

    final newAppointmentId =
        _firestore
            .collection(FirestoreCollections.appointments)
            .doc()
            .id;
    final dateStr =
        '${s.selectedDate!.year}-${s.selectedDate!.month.toString().padLeft(2, '0')}-'
        '${s.selectedDate!.day.toString().padLeft(2, '0')}';
    final timeParts = s.selectedTimeSlot!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final startTime = DateTime(
      s.selectedDate!.year,
      s.selectedDate!.month,
      s.selectedDate!.day,
      hour,
      minute,
    );
    final endTime = startTime.add(
      Duration(minutes: s.serviceDurationMinutes),
    );
    final endTimeStr =
        '${endTime.hour.toString().padLeft(2, '0')}:'
        '${endTime.minute.toString().padLeft(2, '0')}';

    final newAppointment = AppointmentEntity(
      appointmentId: newAppointmentId,
      brandId: s.appointment.brandId,
      locationId: s.appointment.locationId,
      userId: s.appointment.userId,
      barberId: s.selectedTimeSlotBarberId ?? s.appointment.barberId,
      serviceIds: s.appointment.serviceIds,
      startTime: startTime,
      endTime: endTime,
      totalPrice: s.appointment.totalPrice,
      status: AppointmentStatus.scheduled,
    );

    final bufferTime = brand?.bufferTime ?? 0;
    final createResult = await _bookingTransaction.createBookingWithSlot(
      appointment: newAppointment,
      barberId: s.selectedTimeSlotBarberId ?? s.appointment.barberId,
      locationId: s.appointment.locationId,
      dateStr: dateStr,
      startTime: s.selectedTimeSlot!,
      endTime: endTimeStr,
      bufferTimeMinutes: bufferTime,
    );

    return createResult.isRight();
  }
}
