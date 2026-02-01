import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barber/core/di.dart';
import 'package:barber/core/state/base_state.dart';
import 'package:barber/features/brand/di.dart';
import 'package:barber/features/home/domain/entities/home_data.dart';
import 'package:barber/features/home/presentation/bloc/home_notifier.dart';
import 'package:barber/features/locations/di.dart';

final homeNotifierProvider =
    StateNotifierProvider<HomeNotifier, BaseState<HomeData>>((ref) {
  final flavor = ref.watch(flavorConfigProvider);
  final brandId = flavor.values.brandConfig.defaultBrandId;
  return HomeNotifier(
    ref.watch(brandRepositoryProvider),
    ref.watch(locationRepositoryProvider),
    brandId,
  );
});
