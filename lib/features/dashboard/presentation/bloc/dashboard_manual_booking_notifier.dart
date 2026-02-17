import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/booking/data/services/booking_transaction.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/booking/domain/entities/time_slot.dart';
import 'package:barber/features/booking/domain/use_cases/calculate_free_slots.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/barbers/domain/repositories/barber_repository.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/locations/domain/repositories/location_repository.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:barber/features/services/domain/repositories/service_repository.dart';

class DashboardManualBookingData {
  const DashboardManualBookingData({
    this.services = const [],
    this.barbers = const [],
    this.locations = const [],
    this.selectedService,
    this.selectedBarber,
    this.selectedLocation,
    this.selectedDate,
    this.selectedTimeSlot,
    this.availableSlots = const [],
    this.isLoadingSlots = false,
  });

  final List<ServiceEntity> services;
  final List<BarberEntity> barbers;
  final List<LocationEntity> locations;
  final ServiceEntity? selectedService;
  final BarberEntity? selectedBarber;
  final LocationEntity? selectedLocation;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;
  final List<TimeSlot> availableSlots;
  final bool isLoadingSlots;

  DashboardManualBookingData copyWith({
    List<ServiceEntity>? services,
    List<BarberEntity>? barbers,
    List<LocationEntity>? locations,
    ServiceEntity? selectedService,
    BarberEntity? selectedBarber,
    LocationEntity? selectedLocation,
    DateTime? selectedDate,
    String? selectedTimeSlot,
    List<TimeSlot>? availableSlots,
    bool? isLoadingSlots,
    bool clearSelectedService = false,
    bool clearSelectedBarber = false,
    bool clearSelectedLocation = false,
    bool clearSelectedDate = false,
    bool clearSelectedTimeSlot = false,
  }) {
    return DashboardManualBookingData(
      services: services ?? this.services,
      barbers: barbers ?? this.barbers,
      locations: locations ?? this.locations,
      selectedService:
          clearSelectedService
              ? null
              : (selectedService ?? this.selectedService),
      selectedBarber:
          clearSelectedBarber ? null : (selectedBarber ?? this.selectedBarber),
      selectedLocation:
          clearSelectedLocation
              ? null
              : (selectedLocation ?? this.selectedLocation),
      selectedDate:
          clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      selectedTimeSlot:
          clearSelectedTimeSlot
              ? null
              : (selectedTimeSlot ?? this.selectedTimeSlot),
      availableSlots: availableSlots ?? this.availableSlots,
      isLoadingSlots: isLoadingSlots ?? this.isLoadingSlots,
    );
  }
}

class DashboardManualBookingNotifier
    extends BaseNotifier<DashboardManualBookingData, Failure> {
  DashboardManualBookingNotifier(
    this._brandId,
    this._serviceRepository,
    this._barberRepository,
    this._locationRepository,
    this._brandRepository,
    this._calculateFreeSlots,
    this._bookingTransaction,
    this._currentUserBarberId,
  );

  final String _brandId;
  final ServiceRepository _serviceRepository;
  final BarberRepository _barberRepository;
  final LocationRepository _locationRepository;
  final BrandRepository _brandRepository;
  final CalculateFreeSlots _calculateFreeSlots;
  final BookingTransaction _bookingTransaction;
  final String? _currentUserBarberId;

  Future<void> load() async {
    await execute(() async {
      final servicesResult = await _serviceRepository.getByBrandId(_brandId);
      final locationsResult = await _locationRepository.getByBrandId(_brandId);
      final barbersResult = await _barberRepository.getByBrandId(_brandId);

      return servicesResult.fold(
        (f) => Left(f),
        (services) {
          return locationsResult.fold(
            (f) => Left(f),
            (locations) {
              return barbersResult.fold(
                (f) => Left(f),
                (barbers) {
                  BarberEntity? preSelectedBarber;
                  if (_currentUserBarberId != null) {
                    try {
                      preSelectedBarber = barbers.firstWhere(
                        (b) => b.barberId == _currentUserBarberId,
                      );
                    } catch (_) {}
                  }

                  LocationEntity? preSelectedLocation;
                  if (preSelectedBarber != null &&
                      preSelectedBarber.locationId.isNotEmpty) {
                    try {
                      preSelectedLocation = locations.firstWhere(
                        (l) => l.locationId == preSelectedBarber!.locationId,
                      );
                    } catch (_) {}
                  } else if (locations.length == 1) {
                    preSelectedLocation = locations.first;
                  }

                  final activeBarbers = barbers.where((b) => b.active).toList();
                  if (preSelectedBarber != null && !preSelectedBarber.active) {
                    preSelectedBarber = null;
                  }

                  return Right(
                    DashboardManualBookingData(
                      services: services,
                      locations: locations,
                      barbers: activeBarbers,
                      selectedBarber: preSelectedBarber,
                      selectedLocation: preSelectedLocation,
                    ),
                  );
                },
              );
            },
          );
        },
      );
    }, (f) => f.message);
  }

  void selectLocation(LocationEntity location) {
    if (!hasData) return;
    final currentData = data!;

    BarberEntity? newBarber = currentData.selectedBarber;
    if (newBarber != null &&
        newBarber.locationId != location.locationId &&
        newBarber.locationId.isNotEmpty) {
      newBarber = null;
    }

    setData(
      currentData.copyWith(
        selectedLocation: location,
        selectedBarber: newBarber,
        clearSelectedBarber: newBarber == null,
        clearSelectedDate: true,
        clearSelectedTimeSlot: true,
        availableSlots: [],
      ),
    );
  }

  void selectService(ServiceEntity service) {
    if (!hasData) return;
    final currentData = data!;
    setData(
      currentData.copyWith(
        selectedService: service,
        clearSelectedDate: true,
        clearSelectedTimeSlot: true,
        availableSlots: [],
      ),
    );
  }

  void selectBarber(BarberEntity barber) {
    if (!hasData) return;
    final currentData = data!;

    LocationEntity? newLocation = currentData.selectedLocation;
    if (barber.locationId.isNotEmpty) {
      try {
        newLocation = currentData.locations.firstWhere(
          (l) => l.locationId == barber.locationId,
        );
      } catch (_) {}
    }

    setData(
      currentData.copyWith(
        selectedBarber: barber,
        selectedLocation: newLocation,
        clearSelectedDate: true,
        clearSelectedTimeSlot: true,
        availableSlots: [],
      ),
    );
  }

  void selectDate(DateTime date) {
    if (!hasData) return;
    setData(
      data!.copyWith(
        selectedDate: date,
        clearSelectedTimeSlot: true,
        availableSlots: [],
      ),
    );
    _fetchSlots();
  }

  void selectTimeSlot(String timeSlot) {
    if (!hasData) return;
    setData(data!.copyWith(selectedTimeSlot: timeSlot));
  }

  Future<void> _fetchSlots() async {
    if (!hasData) return;
    final currentData = data!;

    if (currentData.selectedService == null ||
        currentData.selectedBarber == null ||
        currentData.selectedLocation == null ||
        currentData.selectedDate == null) {
      return;
    }

    setData(currentData.copyWith(isLoadingSlots: true));

    try {
      final brandResult = await _brandRepository.getById(_brandId);
      final brand = brandResult.getOrElse(() => null);
      if (brand == null) {
        setData(currentData.copyWith(isLoadingSlots: false));
        return;
      }

      // Check if date is today -> filter out past times
      final now = DateTime.now();
      final isToday =
          currentData.selectedDate!.year == now.year &&
          currentData.selectedDate!.month == now.month &&
          currentData.selectedDate!.day == now.day;
      final minStartTime = isToday ? now : null;

      final slots = await _calculateFreeSlots.getFreeSlotsForBarber(
        barber: currentData.selectedBarber!,
        location: currentData.selectedLocation!,
        date: currentData.selectedDate!,
        slotIntervalMinutes: brand.slotInterval,
        serviceDurationMinutes: currentData.selectedService!.durationMinutes,
        bufferTimeMinutes: brand.bufferTime,
        minStartTime: minStartTime,
      );

      setData(
        currentData.copyWith(availableSlots: slots, isLoadingSlots: false),
      );
    } catch (e) {
      setData(currentData.copyWith(isLoadingSlots: false));
    }
  }

  /// Returns null on success, error message on failure.
  Future<String?> submit({
    required String customerName,
    required String customerPhone,
  }) async {
    if (!hasData) return "Data not loaded";
    final currentData = data!;

    if (currentData.selectedService == null ||
        currentData.selectedBarber == null ||
        currentData.selectedLocation == null ||
        currentData.selectedDate == null ||
        currentData.selectedTimeSlot == null) {
      return "All fields are required";
    }

    final appointmentId = const Uuid().v4();
    final userId = 'manual_${const Uuid().v4()}';

    final date = currentData.selectedDate!;
    final timeParts = currentData.selectedTimeSlot!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final startTime = DateTime(date.year, date.month, date.day, hour, minute);
    final endTime = startTime.add(
      Duration(minutes: currentData.selectedService!.durationMinutes),
    );

    final appointment = AppointmentEntity(
      appointmentId: appointmentId,
      brandId: _brandId,
      locationId: currentData.selectedLocation!.locationId,
      userId: userId,
      barberId: currentData.selectedBarber!.barberId,
      serviceIds: [currentData.selectedService!.serviceId],
      startTime: startTime,
      endTime: endTime,
      totalPrice: currentData.selectedService!.price,
      status: AppointmentStatus.scheduled,
      customerName: customerName,
      customerPhone: customerPhone,
      serviceName: currentData.selectedService!.name,
      barberName: currentData.selectedBarber!.name,
      createdAt: DateTime.now(),
    );

    final brandResult = await _brandRepository.getById(_brandId);
    final brand = brandResult.getOrElse(() => null);
    if (brand == null) {
      return "Brand not found";
    }

    try {
      final result = await _bookingTransaction.createBookingWithSlot(
        appointment: appointment,
        barberId: appointment.barberId,
        locationId: appointment.locationId,
        brandId: _brandId,
        dateStr:
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        startTime: currentData.selectedTimeSlot!,
        endTime:
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        bufferTimeMinutes: brand.bufferTime,
      );

      return result.fold((f) => f.message, (_) => null);
    } catch (e) {
      return e.toString();
    }
  }
}
