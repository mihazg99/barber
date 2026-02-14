import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/router/app_routes.dart';
import 'package:barber/core/utils/snackbar_helper.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/widgets/custom_app_bar.dart';
import 'package:barber/features/booking/domain/entities/booking_draft.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/auth/di.dart';
import 'package:barber/features/booking/di.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/booking/domain/entities/appointment_entity.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:barber/features/booking/presentation/widgets/booking_progress_bar.dart';
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
/// Supports quick-action from home: pass [initialBarberId], [initialServiceId], and [initialLocationId] from route query.
class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({
    super.key,
    this.initialBarberId,
    this.initialServiceId,
    this.initialLocationId,
  });

  final String? initialBarberId;
  final String? initialServiceId;
  final String? initialLocationId;

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  bool _isConfirming = false;
  bool _initialized = false;
  List<TimeSlot>? _lastTimeSlots;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _dateSectionKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Defer so we don't modify provider (notifier.initialize) during build/didChangeDependencies.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if still mounted before initializing (prevents initialization during logout/navigation)
        if (mounted) {
          _initializeFromQueryParams(
            barberId: widget.initialBarberId,
            serviceId: widget.initialServiceId,
            locationId: widget.initialLocationId,
          );
        }
      });
    }
  }

  Future<void> _initializeFromQueryParams({
    String? barberId,
    String? serviceId,
    String? locationId,
  }) async {
    if (!mounted) return;

    final userId = ref.read(authRepositoryProvider).currentUserId;
    final guestStorage = ref.read(guestStorageProvider);
    final draftJson = guestStorage.getBookingDraftJson();

    if (userId != null && draftJson != null && draftJson.isNotEmpty) {
      final draft = BookingDraft.fromJsonString(draftJson);
      if (draft != null && mounted) {
        await _restoreFromDraft(draft);
        if (mounted) {
          guestStorage.clearBookingDraft();
        }
        return;
      }
    }

    if (!mounted) return;

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

    if (!mounted) return;

    await ref
        .read(bookingNotifierProvider.notifier)
        .initialize(
          isQuickBook: isQuickBook,
          barberId: isQuickBook ? barberId : null,
          preSelectedBarber: preSelectedBarber,
          preSelectedService: preSelectedService,
          preSelectedLocationId: locationId,
          allServices: services,
          locations: locations,
        );
  }

  Future<void> _restoreFromDraft(BookingDraft draft) async {
    if (!mounted) return;

    final servicesAsync = ref.read(servicesForHomeProvider);
    final services = servicesAsync.valueOrNull ?? [];
    final barbersAsync = ref.read(barbersForHomeProvider);
    final barbers = barbersAsync.valueOrNull ?? [];
    final homeState = ref.read(homeNotifierProvider);
    final locations =
        homeState is BaseData<HomeData>
            ? homeState.data.locations
            : <LocationEntity>[];

    ServiceEntity? preSelectedService;
    try {
      preSelectedService = services.firstWhere(
        (s) => s.serviceId == draft.serviceId,
      );
    } catch (_) {
      preSelectedService = null;
    }

    BarberEntity? preSelectedBarber;
    if (draft.barberId != null && draft.barberId!.isNotEmpty) {
      try {
        preSelectedBarber = barbers.firstWhere(
          (b) => b.barberId == draft.barberId,
        );
      } catch (_) {
        preSelectedBarber = null;
      }
    } else {
      preSelectedBarber = null;
    }

    if (!mounted) return;

    final notifier = ref.read(bookingNotifierProvider.notifier);
    await notifier.initialize(
      isQuickBook: preSelectedBarber != null,
      barberId: draft.barberId,
      preSelectedBarber: preSelectedBarber,
      preSelectedService: preSelectedService,
      preSelectedLocationId: draft.locationId,
      allServices: services,
      locations: locations,
    );

    if (!mounted) return;

    DateTime? date;
    try {
      date = DateTime.parse(draft.dateIso);
    } catch (_) {}
    if (date != null) notifier.selectDate(date);
    notifier.selectTimeSlot(
      draft.timeSlot,
      barberId: draft.timeSlotBarberId,
    );
  }

  Future<void> _confirmBooking() async {
    setState(() => _isConfirming = true);
    final alreadyHasUpcomingMsg = context.l10n.bookingAlreadyHasUpcoming;

    try {
      final bookingState = ref.read(bookingNotifierProvider);
      final userId = ref.read(authRepositoryProvider).currentUserId;
      final brandId = ref.read(lockedBrandIdProvider);

      if (brandId == null) {
        _showError('No brand selected');
        return;
      }

      if (userId == null) {
        final draft = BookingDraft(
          brandId: brandId,
          locationId: bookingState.locationId!,
          serviceId: bookingState.selectedService!.serviceId,
          barberId: bookingState.selectedBarber?.barberId,
          dateIso:
              '${bookingState.selectedDate!.year}-${bookingState.selectedDate!.month.toString().padLeft(2, '0')}-${bookingState.selectedDate!.day.toString().padLeft(2, '0')}',
          timeSlot: bookingState.selectedTimeSlot!,
          timeSlotBarberId: bookingState.selectedTimeSlotBarberId,
        );
        ref
            .read(guestStorageProvider)
            .setBookingDraftJson(draft.toJsonString());
        if (mounted) {
          showSuccessSnackBar(
            context,
            message: context.l10n.signInToContinue,
          );
          // Show the login overlay instead of navigating to auth screen
          ref.read(loginOverlayNotifierProvider.notifier).show();
        }
        if (mounted) setState(() => _isConfirming = false);
        return;
      }

      // Block more than one upcoming appointment per user per brand
      final existingResult = await ref
          .read(appointmentRepositoryProvider)
          .getByUserId(userId, brandId);
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
        final upcomingState = ref.read(upcomingAppointmentProvider);
        final appt =
            upcomingState is BaseData<AppointmentEntity?>
                ? upcomingState.data
                : null;
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

      // Get user data for customer name
      final userResult = await ref.read(userRepositoryProvider).getById(userId);
      final customerName = userResult.fold(
        (_) => 'Customer',
        (user) => user?.fullName ?? 'Customer',
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
        customerName: customerName,
        serviceName: bookingState.selectedService!.name,
        barberName: bookingState.selectedBarber?.name,
      );

      // Create appointment + update availability in one transaction (prevents double booking)
      final transaction = ref.read(bookingTransactionProvider);
      final result = await transaction.createBookingWithSlot(
        appointment: appointment,
        barberId: bookingState.effectiveBarberId,
        locationId: bookingState.locationId!,
        brandId: brandId,
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
          final upcomingState = ref.read(upcomingAppointmentProvider);
          final appt =
              upcomingState is BaseData<AppointmentEntity?>
                  ? upcomingState.data
                  : null;
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

  void _scrollToDateSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _dateSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.1, // Scroll to show near top with some padding
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final showLocationStep = locations.isNotEmpty;
    final locationSelected = bookingState.locationId != null;

    // Show only services available at the selected location (empty list = all locations)
    final services =
        allServices
            .where((s) => s.isAvailableAt(bookingState.locationId))
            .toList();

    // Filter barbers by location if we have one
    final barbersFiltered =
        bookingState.locationId != null
            ? allBarbers
                .where(
                  (b) =>
                      b.locationId == bookingState.locationId ||
                      b.locationId.isEmpty,
                )
                .toList()
            : allBarbers;
    // Sort so preselected barber (from quick book) is first after "Any Barber" for visibility
    final barbers =
        bookingState.preselectedBarberId == null ||
                bookingState.preselectedBarberId!.isEmpty
            ? barbersFiltered
            : [
              ...barbersFiltered.where(
                (b) => b.barberId == bookingState.preselectedBarberId,
              ),
              ...barbersFiltered.where(
                (b) => b.barberId != bookingState.preselectedBarberId,
              ),
            ];

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

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
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
                  if (bookingState.selectedService != null ||
                      bookingState.barberChoiceMade) ...[
                    BookingBarberSection(
                      barbers: barbers,
                      selectedBarberId: bookingState.selectedBarber?.barberId,
                      isAnyBarber:
                          bookingState.isAnyBarber &&
                          bookingState.barberChoiceMade,
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
                      bookingState.barberChoiceMade) ...[
                    Container(
                      key: _dateSectionKey,
                      child: BookingDateSection(
                        selectedDate: bookingState.selectedDate,
                        onDateSelected: (date) {
                          ref
                              .read(bookingNotifierProvider.notifier)
                              .selectDate(date);
                          _scrollToDateSection();
                        },
                      ),
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
