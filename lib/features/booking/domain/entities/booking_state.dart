import 'package:equatable/equatable.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';

/// Booking flow state.
class BookingState extends Equatable {
  const BookingState({
    this.selectedService,
    this.selectedBarber,
    this.selectedDate,
    this.selectedTimeSlot,
    this.selectedTimeSlotBarberId,
    this.locationId,
    this.barberChoiceMade = false,
  });

  final ServiceEntity? selectedService;
  final BarberEntity? selectedBarber; // null = "Any Barber"
  final DateTime? selectedDate;
  final String? selectedTimeSlot; // e.g. "09:00"
  final String? selectedTimeSlotBarberId; // When "Any Barber" + time selected
  final String? locationId; // Derived or default location
  /// True when user or quick book has chosen a barber (specific or "Any barber").
  /// When false with selectedBarber == null, stepper shows barber step as not completed.
  final bool barberChoiceMade;

  bool get isAnyBarber => selectedBarber == null;

  bool get canConfirm =>
      selectedService != null &&
      selectedDate != null &&
      selectedTimeSlot != null;

  num get totalPrice => selectedService?.price ?? 0;

  int get totalDurationMinutes => selectedService?.durationMinutes ?? 0;

  String get effectiveBarberId {
    if (selectedBarber != null) return selectedBarber!.barberId;
    if (selectedTimeSlotBarberId != null) return selectedTimeSlotBarberId!;
    return '';
  }

  BookingState copyWith({
    ServiceEntity? selectedService,
    BarberEntity? selectedBarber,
    DateTime? selectedDate,
    String? selectedTimeSlot,
    String? selectedTimeSlotBarberId,
    String? locationId,
    bool? barberChoiceMade,
    bool clearBarber = false,
    bool clearDate = false,
    bool clearTimeSlot = false,
    bool clearTimeSlotBarberId = false,
  }) {
    return BookingState(
      selectedService: selectedService ?? this.selectedService,
      selectedBarber:
          clearBarber ? null : (selectedBarber ?? this.selectedBarber),
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
      selectedTimeSlot:
          clearTimeSlot ? null : (selectedTimeSlot ?? this.selectedTimeSlot),
      selectedTimeSlotBarberId:
          clearTimeSlotBarberId
              ? null
              : (selectedTimeSlotBarberId ?? this.selectedTimeSlotBarberId),
      locationId: locationId ?? this.locationId,
      barberChoiceMade: barberChoiceMade ?? this.barberChoiceMade,
    );
  }

  @override
  List<Object?> get props => [
    selectedService,
    selectedBarber,
    selectedDate,
    selectedTimeSlot,
    selectedTimeSlotBarberId,
    locationId,
    barberChoiceMade,
  ];
}
