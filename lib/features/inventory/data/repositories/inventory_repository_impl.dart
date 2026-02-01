import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/utils/generic_mapper.dart';
import 'package:barber/features/inventory/data/datasources/inventory_local_data_source.dart';
import 'package:barber/features/inventory/data/mappers/entity_mapper.dart';
import 'package:barber/features/inventory/domain/entities/location_entity.dart';
import 'package:barber/features/inventory/domain/entities/box_entity.dart';
import 'package:barber/features/inventory/domain/entities/item_entity.dart';
import 'package:barber/features/inventory/domain/entities/category_entity.dart';
import 'package:barber/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:barber/features/inventory/domain/failures/inventory_failures.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryLocalDataSource _localDataSource;

  InventoryRepositoryImpl(this._localDataSource);

  // ===== LOCATIONS CRUD =====

  @override
  Future<Either<Failure, List<LocationEntity>>> getAllLocations() async {
    try {
      final locations = await _localDataSource.getAllLocations();
      return Right(locations.mapTo(mapLocationToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to get locations: $e'));
    }
  }

  @override
  Future<Either<Failure, LocationEntity?>> getLocationById(int id) async {
    try {
      final location = await _localDataSource.getLocationById(id);
      return Right(location?.mapTo(mapLocationToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to get location by ID: $e'));
    }
  }

  @override
  Future<Either<Failure, List<LocationEntity>>> searchLocationsByName(
    String searchTerm,
  ) async {
    try {
      final locations = await _localDataSource.searchLocationsByName(
        searchTerm,
      );
      return Right(locations.mapTo(mapLocationToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to search locations: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> insertLocation(LocationEntity location) async {
    try {
      final companion = mapLocationEntityToCompanion(location);
      final id = await _localDataSource.insertLocation(companion);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('Failed to insert location: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateLocation(LocationEntity location) async {
    try {
      final companion = mapLocationEntityToCompanion(location);
      final success = await _localDataSource.updateLocation(companion);
      return Right(success);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update location: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteLocation(int id) async {
    try {
      final deletedCount = await _localDataSource.deleteLocation(id);
      if (deletedCount == 0) {
        return Left(NotFoundFailure('Location not found'));
      }
      return Right(deletedCount);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete location: $e'));
    }
  }

  // ===== BOXES CRUD =====

  @override
  Future<Either<Failure, List<BoxEntity>>> getAllBoxes() async {
    try {
      final boxes = await _localDataSource.getAllBoxesWithItems();
      return Right(boxes);
    } catch (e) {
      return Left(DatabaseFailure('Failed to get boxes: $e'));
    }
  }

  @override
  Future<Either<Failure, BoxEntity?>> getBoxById(int id) async {
    try {
      final box = await _localDataSource.getBoxById(id);
      return Right(box?.mapTo(mapBoxToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to get box by ID: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BoxEntity>>> getBoxesByLocation(
    int locationId,
  ) async {
    try {
      final boxes = await _localDataSource.getBoxesByLocation(locationId);
      return Right(boxes.mapTo(mapBoxToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to get boxes by location: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BoxEntity>>> searchBoxesByLabel(
    String searchTerm,
  ) async {
    try {
      final boxes = await _localDataSource.searchBoxesByLabel(searchTerm);
      return Right(boxes.mapTo(mapBoxToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to search boxes: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> insertBox(BoxEntity box) async {
    try {
      final companion = mapBoxEntityToCompanion(box);
      final id = await _localDataSource.insertBox(companion);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('Failed to insert box: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateBox(BoxEntity box) async {
    try {
      final companion = mapBoxEntityToCompanion(box);
      final success = await _localDataSource.updateBox(companion);
      return Right(success);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update box: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteBox(int id) async {
    try {
      final deletedCount = await _localDataSource.deleteBox(id);
      if (deletedCount == 0) {
        return Left(NotFoundFailure('Box not found'));
      }
      return Right(deletedCount);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete box: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteBoxesInLocation(int locationId) async {
    try {
      final deletedCount = await _localDataSource.deleteBoxesInLocation(
        locationId,
      );
      return Right(deletedCount);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete boxes in location: $e'));
    }
  }

  // ===== ITEMS CRUD =====

  @override
  Future<Either<Failure, List<ItemEntity>>> getAllItems() async {
    try {
      final items = await _localDataSource.getAllItems();
      return Right(items.mapTo(mapItemToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to get items: $e'));
    }
  }

  @override
  Future<Either<Failure, ItemEntity?>> getItemById(int id) async {
    try {
      final item = await _localDataSource.getItemById(id);
      return Right(item?.mapTo(mapItemToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to get item by ID: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ItemEntity>>> getItemsInBox(int boxId) async {
    try {
      final items = await _localDataSource.getItemsInBox(boxId);
      return Right(items.mapTo(mapItemToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to get items in box: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ItemEntity>>> searchItemsByName(
    String searchTerm,
  ) async {
    try {
      final items = await _localDataSource.searchItemsByName(searchTerm);
      return Right(items.mapTo(mapItemToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to search items: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ItemEntity>>> getItemsWithLowQuantity(
    int threshold,
  ) async {
    try {
      final items = await _localDataSource.getItemsWithLowQuantity(threshold);
      return Right(items.mapTo(mapItemToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to get items with low quantity: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> insertItem(ItemEntity item) async {
    try {
      final companion = mapItemEntityToCompanion(item);
      final id = await _localDataSource.insertItem(companion);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('Failed to insert item: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateItem(ItemEntity item) async {
    try {
      final companion = mapItemEntityToCompanion(item);
      final success = await _localDataSource.updateItem(companion);
      return Right(success);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update item: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateItemQuantity(
    int itemId,
    int newQuantity,
  ) async {
    try {
      if (newQuantity < 0) {
        return Left(ValidationFailure('Quantity cannot be negative'));
      }

      final success = await _localDataSource.updateItemQuantity(
        itemId,
        newQuantity,
      );
      return Right(success);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update item quantity: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteItem(int id) async {
    try {
      final deletedCount = await _localDataSource.deleteItem(id);
      if (deletedCount == 0) {
        return Left(NotFoundFailure('Item not found'));
      }
      return Right(deletedCount);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete item: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteItemsInBox(int boxId) async {
    try {
      final deletedCount = await _localDataSource.deleteItemsInBox(boxId);
      return Right(deletedCount);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete items in box: $e'));
    }
  }

  // ===== CATEGORIES CRUD =====

  @override
  Future<Either<Failure, List<CategoryEntity>>> getAllCategories() async {
    try {
      final categories = await _localDataSource.getAllCategories();
      return Right(categories.mapTo(mapCategoryToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to get categories: $e'));
    }
  }

  @override
  Future<Either<Failure, CategoryEntity?>> getCategoryById(int id) async {
    try {
      final category = await _localDataSource.getCategoryById(id);
      return Right(category?.mapTo(mapCategoryToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to get category by ID: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> searchCategoriesByName(
    String searchTerm,
  ) async {
    try {
      final categories = await _localDataSource.searchCategoriesByName(
        searchTerm,
      );
      return Right(categories.mapTo(mapCategoryToEntity));
    } catch (e) {
      return Left(DatabaseFailure('Failed to search categories: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> insertCategory(CategoryEntity category) async {
    try {
      final companion = mapCategoryEntityToCompanion(category);
      final id = await _localDataSource.insertCategory(companion);
      return Right(id);
    } catch (e) {
      return Left(DatabaseFailure('Failed to insert category: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateCategory(CategoryEntity category) async {
    try {
      final companion = mapCategoryEntityToCompanion(category);
      final success = await _localDataSource.updateCategory(companion);
      return Right(success);
    } catch (e) {
      return Left(DatabaseFailure('Failed to update category: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteCategory(int id) async {
    try {
      final deletedCount = await _localDataSource.deleteCategory(id);
      if (deletedCount == 0) {
        return Left(NotFoundFailure('Category not found'));
      }
      return Right(deletedCount);
    } catch (e) {
      return Left(DatabaseFailure('Failed to delete category: $e'));
    }
  }
}
