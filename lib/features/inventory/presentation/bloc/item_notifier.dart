import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/state/base_notifier.dart';
import 'package:barber/features/inventory/domain/entities/item_entity.dart';
import 'package:barber/features/inventory/domain/repositories/inventory_repository.dart';

class ItemNotifier extends BaseNotifier<List<ItemEntity>, Failure> {
  final InventoryRepository _repository;
  int _searchVersion = 0;

  ItemNotifier(this._repository);

  // ===== CRUD OPERATIONS =====

  /// Get all items
  Future<void> getAllItems() async {
    await execute(
      () => _repository.getAllItems(),
      (failure) => failure.message,
    );
  }

  /// Get items in a specific box
  Future<void> getItemsInBox(int boxId) async {
    await execute(
      () => _repository.getItemsInBox(boxId),
      (failure) => failure.message,
    );
  }

  /// Search items by name (with search version to prevent race conditions)
  Future<void> searchItemsByName(String searchTerm) async {
    final currentVersion = ++_searchVersion;
    setLoading();
    final result = await _repository.searchItemsByName(searchTerm);
    if (currentVersion == _searchVersion) {
      result.fold(
        (failure) => setError(failure.message, failure),
        (data) => setData(data),
      );
    }
  }

  /// Get items with low quantity (below threshold)
  Future<void> getItemsWithLowQuantity(int threshold) async {
    await execute(
      () => _repository.getItemsWithLowQuantity(threshold),
      (failure) => failure.message,
    );
  }

  /// Insert a new item and refresh the list
  Future<void> insertItem(ItemEntity item) async {
    final result = await _repository.insertItem(item);
    result.fold(
      (failure) => setError(failure.message, failure),
      (id) => getAllItems(), // Refresh the list after insert
    );
  }

  /// Update an existing item and refresh the list
  Future<void> updateItem(ItemEntity item) async {
    final result = await _repository.updateItem(item);
    result.fold(
      (failure) => setError(failure.message, failure),
      (success) => getAllItems(), // Refresh the list after update
    );
  }

  /// Update item quantity and refresh the list
  Future<void> updateItemQuantity(int itemId, int newQuantity) async {
    final result = await _repository.updateItemQuantity(itemId, newQuantity);
    result.fold(
      (failure) => setError(failure.message, failure),
      (success) => getAllItems(), // Refresh the list after update
    );
  }

  /// Delete an item and refresh the list
  Future<void> deleteItem(int id) async {
    final result = await _repository.deleteItem(id);
    result.fold(
      (failure) => setError(failure.message, failure),
      (deletedCount) => getAllItems(), // Refresh the list after delete
    );
  }

  /// Delete all items in a box and refresh the list
  Future<void> deleteItemsInBox(int boxId) async {
    final result = await _repository.deleteItemsInBox(boxId);
    result.fold(
      (failure) => setError(failure.message, failure),
      (deletedCount) => getAllItems(), // Refresh the list after delete
    );
  }

  // ===== HELPER METHODS =====

  /// Get a specific item by ID from current data
  ItemEntity? getItemByIdFromData(int id) {
    final items = data;
    if (items == null) return null;
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get items for a specific box from current data
  List<ItemEntity> getItemsByBoxFromData(int boxId) {
    final items = data;
    if (items == null) return [];
    return items.where((item) => item.boxId == boxId).toList();
  }

  /// Get items with low quantity from current data
  List<ItemEntity> getItemsWithLowQuantityFromData(int threshold) {
    final items = data;
    if (items == null) return [];
    return items.where((item) => item.quantity < threshold).toList();
  }

  /// Refresh items data
  Future<void> refresh() async {
    await getAllItems();
  }

  /// Clear all data and reset to initial state
  void clear() {
    setInitial();
  }
} 