import 'package:inventory/core/errors/failure.dart';
import 'package:inventory/core/state/base_notifier.dart';
import 'package:inventory/features/inventory/domain/entities/location_entity.dart';
import 'package:inventory/features/inventory/domain/repositories/inventory_repository.dart';

class LocationNotifier extends BaseNotifier<List<LocationEntity>, Failure> {
  final InventoryRepository _repository;

  LocationNotifier(this._repository);

  // ===== CRUD OPERATIONS =====

  /// Get all locations
  Future<void> getAllLocations() async {
    await execute(
      () => _repository.getAllLocations(),
      (failure) => failure.message,
    );
  }

  /// Search locations by name
  Future<void> searchLocationsByName(String searchTerm) async {
    await execute(
      () => _repository.searchLocationsByName(searchTerm),
      (failure) => failure.message,
    );
  }

  /// Insert a new location and refresh the list
  Future<void> insertLocation(LocationEntity location) async {
    final result = await _repository.insertLocation(location);
    result.fold(
      (failure) => setError(failure.message, failure),
      (id) => getAllLocations(), // Refresh the list after insert
    );
  }

  /// Update an existing location and refresh the list
  Future<void> updateLocation(LocationEntity location) async {
    final result = await _repository.updateLocation(location);
    result.fold(
      (failure) => setError(failure.message, failure),
      (success) => getAllLocations(), // Refresh the list after update
    );
  }

  /// Delete a location and refresh the list
  Future<void> deleteLocation(int id) async {
    final result = await _repository.deleteLocation(id);
    result.fold(
      (failure) => setError(failure.message, failure),
      (deletedCount) => getAllLocations(), // Refresh the list after delete
    );
  }

  // ===== HELPER METHODS =====

  /// Get a specific location by ID from current data
  LocationEntity? getLocationByIdFromData(int id) {
    final locations = data;
    if (locations == null) return null;
    try {
      return locations.firstWhere((location) => location.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh locations data
  Future<void> refresh() async {
    await getAllLocations();
  }

  /// Clear all data and reset to initial state
  void clear() {
    setInitial();
  }
} 