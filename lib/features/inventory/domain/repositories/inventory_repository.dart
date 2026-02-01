import 'package:dartz/dartz.dart';
import 'package:inventory/core/errors/failure.dart';
import 'package:inventory/features/inventory/domain/entities/location_entity.dart';
import 'package:inventory/features/inventory/domain/entities/box_entity.dart';
import 'package:inventory/features/inventory/domain/entities/item_entity.dart';
import 'package:inventory/features/inventory/domain/entities/category_entity.dart';

abstract class InventoryRepository {
  // ===== LOCATIONS CRUD =====

  /// Get all locations
  Future<Either<Failure, List<LocationEntity>>> getAllLocations();

  /// Get location by ID
  Future<Either<Failure, LocationEntity?>> getLocationById(int id);

  /// Search locations by name
  Future<Either<Failure, List<LocationEntity>>> searchLocationsByName(
    String searchTerm,
  );

  /// Insert a new location
  Future<Either<Failure, int>> insertLocation(LocationEntity location);

  /// Update an existing location
  Future<Either<Failure, bool>> updateLocation(LocationEntity location);

  /// Delete a location
  Future<Either<Failure, int>> deleteLocation(int id);

  // ===== BOXES CRUD =====

  /// Get all boxes
  Future<Either<Failure, List<BoxEntity>>> getAllBoxes();

  /// Get box by ID
  Future<Either<Failure, BoxEntity?>> getBoxById(int id);

  /// Get boxes by location
  Future<Either<Failure, List<BoxEntity>>> getBoxesByLocation(int locationId);

  /// Search boxes by label
  Future<Either<Failure, List<BoxEntity>>> searchBoxesByLabel(
    String searchTerm,
  );

  /// Insert a new box
  Future<Either<Failure, int>> insertBox(BoxEntity box);

  /// Update an existing box
  Future<Either<Failure, bool>> updateBox(BoxEntity box);

  /// Delete a box
  Future<Either<Failure, int>> deleteBox(int id);

  /// Delete all boxes in a location
  Future<Either<Failure, int>> deleteBoxesInLocation(int locationId);

  // ===== ITEMS CRUD =====

  /// Get all items
  Future<Either<Failure, List<ItemEntity>>> getAllItems();

  /// Get item by ID
  Future<Either<Failure, ItemEntity?>> getItemById(int id);

  /// Get items in a specific box
  Future<Either<Failure, List<ItemEntity>>> getItemsInBox(int boxId);

  /// Search items by name
  Future<Either<Failure, List<ItemEntity>>> searchItemsByName(
    String searchTerm,
  );

  /// Get items with low quantity (below threshold)
  Future<Either<Failure, List<ItemEntity>>> getItemsWithLowQuantity(
    int threshold,
  );

  /// Insert a new item
  Future<Either<Failure, int>> insertItem(ItemEntity item);

  /// Update an existing item
  Future<Either<Failure, bool>> updateItem(ItemEntity item);

  /// Update item quantity
  Future<Either<Failure, bool>> updateItemQuantity(int itemId, int newQuantity);

  /// Delete an item
  Future<Either<Failure, int>> deleteItem(int id);

  /// Delete all items in a box
  Future<Either<Failure, int>> deleteItemsInBox(int boxId);

  // ===== CATEGORIES CRUD =====

  /// Get all categories
  Future<Either<Failure, List<CategoryEntity>>> getAllCategories();

  /// Get category by ID
  Future<Either<Failure, CategoryEntity?>> getCategoryById(int id);

  /// Search categories by name
  Future<Either<Failure, List<CategoryEntity>>> searchCategoriesByName(
    String searchTerm,
  );

  /// Insert a new category
  Future<Either<Failure, int>> insertCategory(CategoryEntity category);

  /// Update an existing category
  Future<Either<Failure, bool>> updateCategory(CategoryEntity category);

  /// Delete a category
  Future<Either<Failure, int>> deleteCategory(int id);
}
