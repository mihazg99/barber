import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/dashboard/presentation/bloc/dashboard_brand_notifier.dart';
import 'package:barber/features/dashboard/presentation/bloc/dashboard_barbers_notifier.dart';
import 'package:barber/features/dashboard/presentation/bloc/dashboard_locations_notifier.dart';
import 'package:barber/features/dashboard/presentation/bloc/dashboard_services_notifier.dart';
import 'package:barber/features/barbers/domain/entities/barber_entity.dart';
import 'package:barber/features/barbers/di.dart' as barbers_di;
import 'package:barber/features/locations/domain/entities/location_entity.dart';
import 'package:barber/features/locations/di.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';
import 'package:barber/features/services/di.dart' as services_di;

final dashboardBrandNotifierProvider =
    StateNotifierProvider<DashboardBrandNotifier, BaseState<BrandEntity?>>((ref) {
  final brandRepo = ref.watch(brandRepositoryProvider);
  final brandId = ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';
  return DashboardBrandNotifier(brandRepo, effectiveBrandId);
});

final dashboardLocationsNotifierProvider =
    StateNotifierProvider<DashboardLocationsNotifier, BaseState<List<LocationEntity>>>((ref) {
  final locationRepo = ref.watch(locationRepositoryProvider);
  final brandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';
  return DashboardLocationsNotifier(locationRepo, effectiveBrandId);
});

final dashboardServicesNotifierProvider =
    StateNotifierProvider<DashboardServicesNotifier, BaseState<List<ServiceEntity>>>((ref) {
  final serviceRepo = ref.watch(services_di.serviceRepositoryProvider);
  final brandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';
  return DashboardServicesNotifier(serviceRepo, effectiveBrandId);
});

final dashboardBarbersNotifierProvider =
    StateNotifierProvider<DashboardBarbersNotifier, BaseState<List<BarberEntity>>>((ref) {
  final barberRepo = ref.watch(barbers_di.barberRepositoryProvider);
  final brandId =
      ref.watch(flavorConfigProvider).values.brandConfig.defaultBrandId;
  final effectiveBrandId = brandId.isNotEmpty ? brandId : 'default';
  return DashboardBarbersNotifier(barberRepo, effectiveBrandId);
});
