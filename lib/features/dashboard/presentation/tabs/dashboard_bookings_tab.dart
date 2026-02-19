import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:barber/core/l10n/app_localizations_ext.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/core/theme/app_colors.dart';
import 'package:barber/core/theme/app_sizes.dart';
import 'package:barber/core/theme/app_text_styles.dart';
import 'package:barber/features/home/di.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/dashboard/di.dart';
import 'package:barber/features/home/presentation/widgets/upcoming_booking_card.dart';
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/dashboard/presentation/pages/dashboard_manual_booking_page.dart';

/// Barber bookings tab: shows a full list of upcoming appointments.
class DashboardBookingsTab extends HookConsumerWidget {
  const DashboardBookingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(barberUpcomingAppointmentsProvider);
    final homeState = ref.watch(homeNotifierProvider);
    final locations =
        homeState is BaseData<HomeData>
            ? homeState.data.locations
            : <LocationEntity>[];
    final isLocationsLoading = homeState is BaseLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DashboardManualBookingPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: context.appColors.primaryColor,
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return _EmptyBookingsView();
          }

          return ListView.builder(
            padding: EdgeInsets.all(context.appSizes.paddingMedium),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final a = appointments[index];
              final locationName = _locationNameFor(locations, a.locationId);
              return Padding(
                padding: EdgeInsets.only(bottom: context.appSizes.paddingSmall),
                child: UpcomingBookingCard(
                  appointment: a,
                  locationName: locationName,
                  isLocationsLoading: isLocationsLoading,
                  isProfessionalView: true,
                ),
              );
            },
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
      ),
    );
  }

  static String? _locationNameFor(
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

class _EmptyBookingsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: context.appColors.primaryColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.barberHomeUpcomingEmpty,
            style: context.appTextStyles.bold.copyWith(
              fontSize: 18,
              color: context.appColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
