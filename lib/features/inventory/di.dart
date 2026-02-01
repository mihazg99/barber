import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory/core/di.dart';
import 'package:inventory/core/state/base_state.dart';
import 'package:inventory/features/inventory/data/datasources/inventory_local_data_source.dart';
import 'package:inventory/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:inventory/features/inventory/domain/entities/location_entity.dart';
import 'package:inventory/features/inventory/domain/entities/box_entity.dart';
import 'package:inventory/features/inventory/domain/entities/item_entity.dart';
import 'package:inventory/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:inventory/features/inventory/presentation/bloc/add_item/image_picker_notifier.dart';
import 'package:inventory/features/inventory/presentation/bloc/location_notifier.dart';
import 'package:inventory/features/inventory/presentation/bloc/box_notifier.dart';
import 'package:inventory/features/inventory/presentation/bloc/item_notifier.dart';
import 'package:inventory/features/inventory/presentation/bloc/search_notifier.dart';
import 'package:inventory/features/inventory/presentation/widgets/search_type_toggle.dart';

// ===== DATA SOURCE PROVIDER =====

final inventoryLocalDataSourceProvider = Provider<InventoryLocalDataSource>((
  ref,
) {
  final database = ref.watch(appDatabaseProvider);
  return InventoryLocalDataSource(database);
});

// ===== REPOSITORY PROVIDER =====

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final localDataSource = ref.watch(inventoryLocalDataSourceProvider);
  return InventoryRepositoryImpl(localDataSource);
});

// ===== NOTIFIER PROVIDERS =====

/// Provider for location state management
final locationNotifierProvider =
    StateNotifierProvider<LocationNotifier, BaseState<List<LocationEntity>>>((
      ref,
    ) {
      final repository = ref.watch(inventoryRepositoryProvider);
      return LocationNotifier(repository);
    });

/// Provider for box state management
final boxNotifierProvider =
    StateNotifierProvider<BoxNotifier, BaseState<List<BoxEntity>>>((ref) {
      final repository = ref.watch(inventoryRepositoryProvider);
      return BoxNotifier(repository);
    });

/// Provider for item state management
final itemNotifierProvider =
    StateNotifierProvider<ItemNotifier, BaseState<List<ItemEntity>>>((ref) {
      final repository = ref.watch(inventoryRepositoryProvider);
      return ItemNotifier(repository);
    });

/// Provider for search state management
final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, BaseState<SearchType>>((ref) {
      return SearchNotifier(ref);
    });

/// Provider for current search type
final currentSearchTypeProvider = StateProvider<SearchType>(
  (ref) => SearchType.items,
);

final imagePickerProvider =
    StateNotifierProvider.autoDispose<ImagePickerNotifier, BaseState<String>>(
      (ref) => ImagePickerNotifier(),
    );
