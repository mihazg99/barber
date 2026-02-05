import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber/features/booking/domain/entities/booking_state.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/barbers/domain/repositories/barber_repository.dart';
import 'package:barber/features/locations/domain/repositories/location_repository.dart';

class BookingNotifier extends StateNotifier<BookingState> {
  BookingNotifier(
    this._barberRepository,
    this._locationRepository,
    this._brandId,
  ) : super(const BookingState());

  final BarberRepository _barberRepository;
  final LocationRepository _locationRepository;
  final String _brandId;

  /// Initialize with query params. Only preselect barber when [isQuickBook] is
  /// true (e.g. user came from home with barberId), so the stepper does not
  /// show barber as completed before the user has chosen.
  /// When brand has multiple [locations], location is not set so user selects
  /// it first; when single location it is set automatically.
  Future<void> initialize({
    required bool isQuickBook,
    String? barberId,
    BarberEntity? preSelectedBarber,
    ServiceEntity? preSelectedService,
    List<ServiceEntity>? allServices,
    List<LocationEntity>? locations,
  }) async {
    BarberEntity? barber;
    if (isQuickBook && (preSelectedBarber != null || barberId != null)) {
      barber = preSelectedBarber;
      if (barber == null && barberId != null && barberId.isNotEmpty) {
        final result = await _barberRepository.getById(barberId);
        barber = result.fold((_) => null, (b) => b);
      }
    }

    String? locationId;
    if (barber != null) {
      locationId = barber.locationId;
    } else if (locations != null && locations.isNotEmpty) {
      if (locations.length == 1) {
        locationId = locations.first.locationId;
      }
      // else: multiple locations, leave locationId null so user selects
    } else {
      final locationsResult = await _locationRepository.getByBrandId(_brandId);
      locationsResult.fold(
        (_) => null,
        (list) {
          if (list.length == 1) locationId = list.first.locationId;
        },
      );
    }

    ServiceEntity? effectiveService = preSelectedService;
    if (effectiveService != null &&
        locationId != null &&
        !effectiveService.isAvailableAt(locationId)) {
      effectiveService = null;
    }

    state = state.copyWith(
      selectedBarber: barber,
      selectedService: effectiveService,
      locationId: locationId,
      barberChoiceMade: barber != null,
    );
  }

  void selectLocation(String locationId) {
    final currentService = state.selectedService;
    final serviceStillAvailable =
        currentService == null || currentService.isAvailableAt(locationId);
    state = state.copyWith(
      locationId: locationId,
      clearBarber: true,
      selectedService: serviceStillAvailable ? currentService : null,
      selectedDate: null,
      selectedTimeSlot: null,
      selectedTimeSlotBarberId: null,
      barberChoiceMade: false,
      clearTimeSlot: true,
      clearTimeSlotBarberId: true,
    );
  }

  void selectService(ServiceEntity service) {
    state = state.copyWith(selectedService: service);
  }

  void clearService() {
    state = state.copyWith(selectedService: null);
  }

  void selectBarber(BarberEntity barber) {
    final currentService = state.selectedService;
    final serviceStillAvailable =
        currentService == null ||
        currentService.isAvailableAt(barber.locationId);
    state = state.copyWith(
      selectedBarber: barber,
      locationId: barber.locationId,
      selectedService: serviceStillAvailable ? currentService : null,
      barberChoiceMade: true,
      clearTimeSlot: true, // Clear time when barber changes
      clearTimeSlotBarberId: true,
    );
  }

  void selectAnyBarber() {
    state = state.copyWith(
      clearBarber: true,
      barberChoiceMade: true,
      clearTimeSlot: true,
      clearTimeSlotBarberId: true,
    );
  }

  void selectDate(DateTime date) {
    state = state.copyWith(
      selectedDate: date,
      clearTimeSlot: true, // Clear time when date changes
      clearTimeSlotBarberId: true,
    );
  }

  void clearDate() {
    state = state.copyWith(
      clearDate: true,
      clearTimeSlot: true,
      clearTimeSlotBarberId: true,
    );
  }

  void selectTimeSlot(String timeSlot, {String? barberId}) {
    state = state.copyWith(
      selectedTimeSlot: timeSlot,
      selectedTimeSlotBarberId: barberId,
    );
  }

  void clearTimeSlot() {
    state = state.copyWith(
      clearTimeSlot: true,
      clearTimeSlotBarberId: true,
    );
  }

  /// Reset to initial state. Call when the booking screen is disposed so the
  /// next time the user opens booking they get a fresh form.
  void reset() {
    state = const BookingState();
  }
}
