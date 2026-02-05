import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/utils/snackbar_helper.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/widgets/custom_app_bar.dart';
import 'package:barber/core/di.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/booking/di.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:barber/features/booking/presentation/widgets/booking_progress_bar.dart';
import 'package:barber/features/booking/presentation/widgets/booking_pre_selection_chip.dart';
import 'package:barber/features/booking/presentation/widgets/booking_location_section.dart';
import 'package:barber/features/booking/presentation/widgets/booking_service_section.dart';
import 'package:barber/features/booking/presentation/widgets/booking_barber_section.dart';
import 'package:barber/features/booking/presentation/widgets/booking_date_section.dart';
import 'package:barber/features/booking/presentation/widgets/booking_time_section.dart';
import 'package:barber/features/booking/domain/entities/time_slot.dart';
import 'package:barber/features/booking/presentation/widgets/booking_footer.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';

/// Booking flow: select service, barber, date, and time.
/// Supports quick-action from home: pass [initialBarberId] and [initialServiceId] from route query.
class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({
    super.key,
    this.initialBarberId,
    this.initialServiceId,
  });

  final String? initialBarberId;
  final String? initialServiceId;

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  bool _isConfirming = false;
  bool _initialized = false;
  List<TimeSlot>? _lastTimeSlots;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Defer so we don't modify provider (notifier.initialize) during build/didChangeDependencies.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeFromQueryParams(
          barberId: widget.initialBarberId,
          serviceId: widget.initialServiceId,
        );
      });
    }
  }

  Future<void> _initializeFromQueryParams({
    String? barberId,
    String? serviceId,
  }) async {
    final servicesAsync = ref.read(servicesForHomeProvider);
    final services = servicesAsync.valueOrNull ?? [];
    final barbersAsync = ref.read(barbersForHomeProvider);
    final barbers = barbersAsync.valueOrNull ?? [];
    final homeState = ref.read(homeNotifierProvider);
    final locations =
        homeState is BaseData<HomeData>
            ? homeState.data.locations
            : <LocationEntity>[];

    final isQuickBook = barberId != null && barberId.isNotEmpty;

    ServiceEntity? preSelectedService;
    if (serviceId != null && services.isNotEmpty) {
      try {
        preSelectedService = services.firstWhere(
          (s) => s.serviceId == serviceId,
        );
      } catch (_) {
        preSelectedService = null;
      }
    }

    BarberEntity? preSelectedBarber;
    if (isQuickBook && barbers.isNotEmpty) {
      try {
        preSelectedBarber = barbers.firstWhere((b) => b.barberId == barberId);
      } catch (_) {
        preSelectedBarber = null;
      }
    }

    await ref
        .read(bookingNotifierProvider.notifier)
        .initialize(
          isQuickBook: isQuickBook,
          barberId: isQuickBook ? barberId : null,
          preSelectedBarber: preSelectedBarber,
          preSelectedService: preSelectedService,
          allServices: services,
          locations: locations,
        );
  }

  Future<void> _confirmBooking() async {
    setState(() => _isConfirming = true);
    final alreadyHasUpcomingMsg = context.l10n.bookingAlreadyHasUpcoming;

    try {
      final bookingState = ref.read(bookingNotifierProvider);
      final userId = ref.read(authRepositoryProvider).currentUserId;
      final flavor = ref.read(flavorConfigProvider);
      final brandId = flavor.values.brandConfig.defaultBrandId;

      if (userId == null) {
        _showError(context.l10n.bookingUserNotAuthenticated);
        return;
      }

      // Block more than one upcoming appointment per user
      final existingResult = await ref
          .read(appointmentRepositoryProvider)
          .getByUserId(userId);
      final alreadyHasUpcoming = existingResult.fold(
        (_) => false,
        (list) {
          final now = DateTime.now();
          return list.any(
            (a) =>
                a.status == AppointmentStatus.scheduled &&
                a.startTime.isAfter(now),
          );
        },
      );
      if (alreadyHasUpcoming) {
        if (!mounted) return;
        final appt = ref.read(upcomingAppointmentProvider).valueOrNull;
        // ignore: use_build_context_synchronously
        _showError(
          alreadyHasUpcomingMsg,
          actionLabel: appt != null ? context.l10n.manage : null,
          onAction:
              appt != null
                  ? () => context.go(
                    AppRoute.manageBooking.path.replaceFirst(
                      ':appointmentId',
                      appt.appointmentId,
                    ),
                  )
                  : null,
        );
        return;
      }

      // Get brand for buffer time (used in transaction)
      final brandResult = await ref
          .read(brandRepositoryProvider)
          .getById(brandId);
      final brand = brandResult.fold(
        (_) => null,
        (b) => b,
      );
      final bufferTime = brand?.bufferTime ?? 0;

      // Generate appointment ID (use provider so Firestore has persistence disabled)
      final appointmentId =
          ref
              .read(firebaseFirestoreProvider)
              .collection(FirestoreCollections.appointments)
              .doc()
              .id;

      // Calculate start and end times
      final dateStr = _formatDate(bookingState.selectedDate!);
      final timeSlot = bookingState.selectedTimeSlot!;
      final timeParts = timeSlot.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final startTime = DateTime(
        bookingState.selectedDate!.year,
        bookingState.selectedDate!.month,
        bookingState.selectedDate!.day,
        hour,
        minute,
      );
      final endTime = startTime.add(
        Duration(minutes: bookingState.totalDurationMinutes),
      );

      // Create appointment entity
      final appointment = AppointmentEntity(
        appointmentId: appointmentId,
        brandId: brandId,
        locationId: bookingState.locationId!,
        userId: userId,
        barberId: bookingState.effectiveBarberId,
        serviceIds: [bookingState.selectedService!.serviceId],
        startTime: startTime,
        endTime: endTime,
        totalPrice: bookingState.totalPrice,
        status: AppointmentStatus.scheduled,
      );

      // Create appointment + update availability in one transaction (prevents double booking)
      final transaction = ref.read(bookingTransactionProvider);
      final result = await transaction.createBookingWithSlot(
        appointment: appointment,
        barberId: bookingState.effectiveBarberId,
        locationId: bookingState.locationId!,
        dateStr: dateStr,
        startTime: timeSlot,
        endTime: _formatTime(endTime),
        bufferTimeMinutes: bufferTime,
      );

      await result.fold(
        (failure) async {
          if (!mounted) return;
          final isAlreadyHasUpcoming =
              failure is FirestoreFailure &&
              failure.code == 'user-has-active-appointment';
          final message =
              isAlreadyHasUpcoming ? alreadyHasUpcomingMsg : failure.message;
          final appt = ref.read(upcomingAppointmentProvider).valueOrNull;
          _showError(
            message,
            actionLabel:
                isAlreadyHasUpcoming && appt != null
                    ? context.l10n.manage
                    : null,
            onAction:
                isAlreadyHasUpcoming && appt != null
                    ? () => context.go(
                      AppRoute.manageBooking.path.replaceFirst(
                        ':appointmentId',
                        appt.appointmentId,
                      ),
                    )
                    : null,
          );
          ref.invalidate(availableTimeSlotsProvider);
        },
        (_) async {
          ref.invalidate(upcomingAppointmentProvider);
          ref.invalidate(bookingNotifierProvider);
          _showSuccess();
          if (mounted) context.go(AppRoute.home.path);
        },
      );
    } catch (e) {
      _showError('Failed to create appointment: $e');
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  void _showError(
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    showErrorSnackBar(
      context,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void _showSuccess() {
    if (!mounted) return;
    showSuccessSnackBar(
      context,
      message: context.l10n.bookingAppointmentSuccess,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingNotifierProvider);
    final servicesAsync = ref.watch(servicesForHomeProvider);
    final barbersAsync = ref.watch(barbersForHomeProvider);
    final timeSlotsAsync = ref.watch(availableTimeSlotsProvider);

    // Keep last successful slots so we can show them while refetching (prevents scroll jump on date tap).
    ref.listen(availableTimeSlotsProvider, (prev, next) {
      next.whenData((slots) {
        if (mounted && slots.isNotEmpty) setState(() => _lastTimeSlots = slots);
      });
    });

    final allServices = servicesAsync.valueOrNull ?? [];
    final allBarbers = barbersAsync.valueOrNull ?? [];
    final homeState = ref.watch(homeNotifierProvider);
    final locations =
        homeState is BaseData<HomeData>
            ? homeState.data.locations
            : <LocationEntity>[];
    // When a service is preselected (e.g. quick book), only show locations that offer that service
    final locationsForStep =
        bookingState.selectedService != null
            ? locations
                .where(
                  (loc) => bookingState.selectedService!.isAvailableAt(
                    loc.locationId,
                  ),
                )
                .toList()
            : locations;
    final locationsToShow =
        locationsForStep.isEmpty ? locations : locationsForStep;
    final showLocationStep = locations.length > 1;
    final locationSelected =
        !showLocationStep || bookingState.locationId != null;

    // Show only services available at the selected location (empty list = all locations)
    final services =
        allServices
            .where((s) => s.isAvailableAt(bookingState.locationId))
            .toList();

    // Filter barbers by location if we have one
    final barbers =
        bookingState.locationId != null
            ? allBarbers
                .where((b) => b.locationId == bookingState.locationId)
                .toList()
            : allBarbers;

    return Scaffold(
      backgroundColor: context.appColors.backgroundColor,
      appBar: CustomAppBar.withTitleAndBackButton(
        context.l10n.bookingTitle,
        onBack: () => context.go(AppRoute.home.path),
      ),
      body: Column(
        children: [
          // Progress bar
          BookingProgressBar(
            showLocationStep: showLocationStep,
            locationSelected: locationSelected,
            serviceSelected: bookingState.selectedService != null,
            barberSelected: bookingState.barberChoiceMade,
            timeSelected: bookingState.selectedTimeSlot != null,
          ),

          // Pre-selection chip
          if (bookingState.selectedBarber != null)
            BookingPreSelectionChip(
              barberName: bookingState.selectedBarber!.name,
              onClear:
                  () =>
                      ref
                          .read(bookingNotifierProvider.notifier)
                          .selectAnyBarber(),
            ),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: context.appSizes.paddingMedium,
              ),
              child: Column(
                children: [
                  // Location selection (first step when brand has multiple locations).
                  // Filtered by preselected service when quick book so only supporting locations are shown.
                  if (showLocationStep) ...[
                    BookingLocationSection(
                      locations: locationsToShow,
                      selectedLocationId: bookingState.locationId,
                      onLocationSelected: (location) {
                        ref
                            .read(bookingNotifierProvider.notifier)
                            .selectLocation(location.locationId);
                      },
                    ),
                    Gap(context.appSizes.paddingLarge),
                  ],

                  // Service selection: show when location is selected, or when
                  // quick book preselected a service (so user sees selection and can change it).
                  // Services list is filtered by selected location when set.
                  if (locationSelected ||
                      bookingState.selectedService != null) ...[
                    BookingServiceSection(
                      services: services,
                      selectedServiceId:
                          bookingState.selectedService?.serviceId,
                      onServiceSelected: (service) {
                        ref
                            .read(bookingNotifierProvider.notifier)
                            .selectService(service);
                      },
                    ),
                    Gap(context.appSizes.paddingLarge),
                  ],

                  // Barber selection
                  if (bookingState.selectedService != null) ...[
                    BookingBarberSection(
                      barbers: barbers,
                      selectedBarberId: bookingState.selectedBarber?.barberId,
                      isAnyBarber: bookingState.isAnyBarber,
                      onBarberSelected: (barber) {
                        ref
                            .read(bookingNotifierProvider.notifier)
                            .selectBarber(barber);
                      },
                      onAnyBarberSelected: () {
                        ref
                            .read(bookingNotifierProvider.notifier)
                            .selectAnyBarber();
                      },
                    ),
                    Gap(context.appSizes.paddingLarge),
                  ],

                  // Date selection
                  if (bookingState.selectedService != null &&
                      (bookingState.selectedBarber != null ||
                          bookingState.isAnyBarber)) ...[
                    BookingDateSection(
                      selectedDate: bookingState.selectedDate,
                      onDateSelected: (date) {
                        ref
                            .read(bookingNotifierProvider.notifier)
                            .selectDate(date);
                      },
                    ),
                    Gap(context.appSizes.paddingLarge),
                  ],

                  // Time selection (show last slots while loading to avoid scroll jump on date tap)
                  if (bookingState.selectedDate != null) ...[
                    BookingTimeSection(
                      timeSlots:
                          timeSlotsAsync.isLoading
                              ? (_lastTimeSlots ?? [])
                              : (timeSlotsAsync.valueOrNull ?? []),
                      selectedTimeSlot: bookingState.selectedTimeSlot,
                      onTimeSlotSelected: (slot) {
                        ref
                            .read(bookingNotifierProvider.notifier)
                            .selectTimeSlot(
                              slot.time,
                              barberId: slot.barberId,
                            );
                      },
                      isLoading: timeSlotsAsync.isLoading,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Sticky footer
          BookingFooter(
            totalPrice: bookingState.totalPrice,
            totalDurationMinutes: bookingState.totalDurationMinutes,
            canConfirm: bookingState.canConfirm,
            onConfirm: _confirmBooking,
            isConfirming: _isConfirming,
          ),
        ],
      ),
    );
  }
}
