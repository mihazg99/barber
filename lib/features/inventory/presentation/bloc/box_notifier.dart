import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/inventory/domain/entities/box_entity.dart';
import 'package:barber/features/inventory/domain/repositories/inventory_repository.dart';

class BoxNotifier extends BaseNotifier<List<BoxEntity>, Failure> {
  final InventoryRepository _repository;

  BoxNotifier(this._repository);

  // ===== CRUD OPERATIONS =====

  /// Get all boxes
  Future<void> getAllBoxes() async {
    await execute(
      () => _repository.getAllBoxes(),
      (failure) => failure.message,
    );
  }

  /// Get boxes by location
  Future<void> getBoxesByLocation(int locationId) async {
    await execute(
      () => _repository.getBoxesByLocation(locationId),
      (failure) => failure.message,
    );
  }

  /// Search boxes by label
  Future<void> searchBoxesByLabel(String searchTerm) async {
    await execute(
      () => _repository.searchBoxesByLabel(searchTerm),
      (failure) => failure.message,
    );
  }

  /// Insert a new box and refresh the list
  Future<void> insertBox(BoxEntity box) async {
    final result = await _repository.insertBox(box);
    result.fold(
      (failure) => setError(failure.message, failure),
      (id) => getAllBoxes(), // Refresh the list after insert
    );
  }

  /// Update an existing box and refresh the list
  Future<void> updateBox(BoxEntity box) async {
    final result = await _repository.updateBox(box);
    result.fold(
      (failure) => setError(failure.message, failure),
      (success) => getAllBoxes(), // Refresh the list after update
    );
  }

  /// Delete a box and refresh the list
  Future<void> deleteBox(int id) async {
    final result = await _repository.deleteBox(id);
    result.fold(
      (failure) => setError(failure.message, failure),
      (deletedCount) => getAllBoxes(), // Refresh the list after delete
    );
  }

  /// Delete all boxes in a location and refresh the list
  Future<void> deleteBoxesInLocation(int locationId) async {
    final result = await _repository.deleteBoxesInLocation(locationId);
    result.fold(
      (failure) => setError(failure.message, failure),
      (deletedCount) => getAllBoxes(), // Refresh the list after delete
    );
  }

  // ===== HELPER METHODS =====

  /// Get a specific box by ID from current data
  BoxEntity? getBoxByIdFromData(int id) {
    final boxes = data;
    if (boxes == null) return null;
    try {
      return boxes.firstWhere((box) => box.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get boxes for a specific location from current data
  List<BoxEntity> getBoxesByLocationFromData(int locationId) {
    final boxes = data;
    if (boxes == null) return [];
    return boxes.where((box) => box.locationId == locationId).toList();
  }

  /// Refresh boxes data
  Future<void> refresh() async {
    await getAllBoxes();
  }

  /// Clear all data and reset to initial state
  void clear() {
    setInitial();
  }
}
