import 'package:drift/drift.dart';
import 'package:inventory/core/data/database/app_database.dart';
import 'package:inventory/core/data/database/box_dao.dart';
import 'package:inventory/features/inventory/domain/entities/box_entity.dart';

class InventoryLocalDataSource {
  final AppDatabase db;
  final BoxDao boxDao;

  InventoryLocalDataSource(this.db) : boxDao = BoxDao(db);

  // ===== LOCATIONS OPERATIONS =====

  /// Get all locations
  Future<List<Location>> getAllLocations() {
    return (db.select(db.locations)).get();
  }

  /// Get location by ID
  Future<Location?> getLocationById(int id) {
    return (db.select(db.locations)
      ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Search locations by name
  Future<List<Location>> searchLocationsByName(String searchTerm) {
    return (db.select(db.locations)
      ..where((tbl) => tbl.name.like('%$searchTerm%'))).get();
  }

  /// Insert a new location
  Future<int> insertLocation(LocationsCompanion location) {
    return db.into(db.locations).insert(location);
  }

  /// Update an existing location
  Future<bool> updateLocation(LocationsCompanion location) {
    return db.update(db.locations).replace(location);
  }

  /// Delete a location
  Future<int> deleteLocation(int id) {
    return (db.delete(db.locations)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ===== BOXES OPERATIONS =====

  /// Get all boxes
  Future<List<Box>> getAllBoxes() {
    return (db.select(db.boxes)).get();
  }

  /// Get box by ID
  Future<Box?> getBoxById(int id) {
    return (db.select(db.boxes)
      ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get boxes by location
  Future<List<Box>> getBoxesByLocation(int locationId) {
    return (db.select(db.boxes)
      ..where((tbl) => tbl.locationId.equals(locationId))).get();
  }

  /// Search boxes by label
  Future<List<Box>> searchBoxesByLabel(String searchTerm) {
    return (db.select(db.boxes)
      ..where((tbl) => tbl.label.like('%$searchTerm%'))).get();
  }

  /// Insert a new box
  Future<int> insertBox(BoxesCompanion box) {
    return db.into(db.boxes).insert(box);
  }

  /// Update an existing box
  Future<bool> updateBox(BoxesCompanion box) {
    return db.update(db.boxes).replace(box);
  }

  /// Delete a box
  Future<int> deleteBox(int id) {
    return (db.delete(db.boxes)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Delete all boxes in a location
  Future<int> deleteBoxesInLocation(int locationId) {
    return (db.delete(db.boxes)
      ..where((tbl) => tbl.locationId.equals(locationId))).go();
  }

  /// Get all boxes with their items
  Future<List<BoxEntity>> getAllBoxesWithItems() {
    return boxDao.getAllBoxesWithItems();
  }

  // ===== ITEMS OPERATIONS =====

  /// Get all items
  Future<List<Item>> getAllItems() {
    return (db.select(db.items)).get();
  }

  /// Get item by ID
  Future<Item?> getItemById(int id) {
    return (db.select(db.items)
      ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Get items in a specific box
  Future<List<Item>> getItemsInBox(int boxId) {
    return (db.select(db.items)..where((tbl) => tbl.boxId.equals(boxId))).get();
  }

  /// Search items by name
  Future<List<Item>> searchItemsByName(String searchTerm) {
    return (db.select(db.items)
      ..where((tbl) => tbl.name.like('%$searchTerm%'))).get();
  }

  /// Get items with low quantity (below threshold)
  Future<List<Item>> getItemsWithLowQuantity(int threshold) {
    return (db.select(db.items)
      ..where((tbl) => tbl.quantity.isSmallerThanValue(threshold))).get();
  }

  /// Insert a new item
  Future<int> insertItem(ItemsCompanion item) {
    return db.into(db.items).insert(item);
  }

  /// Update an existing item
  Future<bool> updateItem(ItemsCompanion item) {
    return db.update(db.items).replace(item);
  }

  /// Delete an item
  Future<int> deleteItem(int id) {
    return (db.delete(db.items)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Delete all items in a box
  Future<int> deleteItemsInBox(int boxId) {
    return (db.delete(db.items)..where((tbl) => tbl.boxId.equals(boxId))).go();
  }

  /// Update item quantity
  Future<bool> updateItemQuantity(int itemId, int newQuantity) async {
    // First get the current item to preserve other fields
    final currentItem = await getItemById(itemId);
    if (currentItem == null) return false;

    // Create updated item with new quantity but preserve other fields
    final updatedItem = ItemsCompanion(
      id: Value(itemId),
      quantity: Value(newQuantity),
      name: Value(currentItem.name),
      boxId: Value(currentItem.boxId),
      locationId: Value(currentItem.locationId),
    );

    return updateItem(updatedItem);
  }

  // ===== CATEGORIES OPERATIONS =====

  /// Get all categories
  Future<List<Category>> getAllCategories() {
    return (db.select(db.categories)).get();
  }

  /// Get category by ID
  Future<Category?> getCategoryById(int id) {
    return (db.select(db.categories)
      ..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Search categories by name
  Future<List<Category>> searchCategoriesByName(String searchTerm) {
    return (db.select(db.categories)
      ..where((tbl) => tbl.name.like('%$searchTerm%'))).get();
  }

  /// Insert a new category
  Future<int> insertCategory(CategoriesCompanion category) {
    return db.into(db.categories).insert(category);
  }

  /// Update an existing category
  Future<bool> updateCategory(CategoriesCompanion category) {
    return db.update(db.categories).replace(category);
  }

  /// Delete a category
  Future<int> deleteCategory(int id) {
    return (db.delete(db.categories)..where((tbl) => tbl.id.equals(id))).go();
  }

  // ===== UTILITY QUERIES =====

  /// Get total item count
  Future<int> getTotalItemCount() async {
    final result =
        await (db.selectOnly(db.items)
          ..addColumns([db.items.id.count()])).getSingle();
    return result.read(db.items.id.count()) ?? 0;
  }

  /// Get total box count
  Future<int> getTotalBoxCount() async {
    final result =
        await (db.selectOnly(db.boxes)
          ..addColumns([db.boxes.id.count()])).getSingle();
    return result.read(db.boxes.id.count()) ?? 0;
  }

  /// Get total location count
  Future<int> getTotalLocationCount() async {
    final result =
        await (db.selectOnly(db.locations)
          ..addColumns([db.locations.id.count()])).getSingle();
    return result.read(db.locations.id.count()) ?? 0;
  }

  /// Get items count in a specific box
  Future<int> getItemCountInBox(int boxId) async {
    final result =
        await (db.selectOnly(db.items)
              ..where(db.items.boxId.equals(boxId))
              ..addColumns([db.items.id.count()]))
            .getSingle();
    return result.read(db.items.id.count()) ?? 0;
  }

  /// Get boxes count in a specific location
  Future<int> getBoxCountInLocation(int locationId) async {
    final result =
        await (db.selectOnly(db.boxes)
              ..where(db.boxes.locationId.equals(locationId))
              ..addColumns([db.boxes.id.count()]))
            .getSingle();
    return result.read(db.boxes.id.count()) ?? 0;
  }

  /// Get total quantity of all items
  Future<int> getTotalItemQuantity() async {
    final result =
        await (db.selectOnly(db.items)
          ..addColumns([db.items.quantity.sum()])).getSingle();
    return result.read(db.items.quantity.sum()) ?? 0;
  }

  /// Get total quantity in a specific box
  Future<int> getTotalQuantityInBox(int boxId) async {
    final result =
        await (db.selectOnly(db.items)
              ..where(db.items.boxId.equals(boxId))
              ..addColumns([db.items.quantity.sum()]))
            .getSingle();
    return result.read(db.items.quantity.sum()) ?? 0;
  }
}
