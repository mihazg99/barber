import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barber/features/booking/domain/entities/booking_state.dart';
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

  /// Initialize with query params (barberId, serviceId).
  Future<void> initialize({
    String? barberId,
    ServiceEntity? preSelectedService,
    List<ServiceEntity>? allServices,
  }) async {
    BarberEntity? barber;
    ServiceEntity? service = preSelectedService;

    // Resolve barber from ID
    if (barberId != null && barberId.isNotEmpty) {
      final result = await _barberRepository.getById(barberId);
      result.fold((_) => null, (b) => barber = b);
    }

    // Determine location
    String? locationId;
    if (barber != null) {
      locationId = barber!.locationId;
    } else {
      // Use first location of brand as default
      final locationsResult = await _locationRepository.getByBrandId(_brandId);
      locationsResult.fold(
        (_) => null,
        (locations) {
          if (locations.isNotEmpty) locationId = locations.first.locationId;
        },
      );
    }

    state = state.copyWith(
      selectedBarber: barber,
      selectedService: service,
      locationId: locationId,
    );
  }

  void selectService(ServiceEntity service) {
    state = state.copyWith(selectedService: service);
  }

  void clearService() {
    state = state.copyWith(selectedService: null);
  }

  void selectBarber(BarberEntity barber) {
    state = state.copyWith(
      selectedBarber: barber,
      locationId: barber.locationId,
      clearTimeSlot: true, // Clear time when barber changes
      clearTimeSlotBarberId: true,
    );
  }

  void selectAnyBarber() {
    state = state.copyWith(
      clearBarber: true,
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
