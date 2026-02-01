import 'package:drift/drift.dart';
import 'package:inventory/core/data/database/app_database.dart';
import 'package:inventory/core/utils/generic_mapper.dart';
import 'package:inventory/features/inventory/domain/entities/location_entity.dart';
import 'package:inventory/features/inventory/domain/entities/box_entity.dart';
import 'package:inventory/features/inventory/domain/entities/item_entity.dart';
import 'package:inventory/features/inventory/domain/entities/category_entity.dart';

/// Mapping functions for database models to domain entities
/// Using the generic mapper for cleaner code

// ===== LOCATION MAPPING =====

/// Map Location database model to LocationEntity
LocationEntity mapLocationToEntity(Location location) => location.mapTo(
  (l) => LocationEntity(
    id: l.id,
    name: l.name,
    color: l.color,
  ),
);

/// Map LocationEntity to LocationsCompanion for database operations
LocationsCompanion mapLocationEntityToCompanion(LocationEntity entity) =>
    entity.mapTo(
      (e) => LocationsCompanion(
        id: e.id == 0 ? const Value.absent() : Value(e.id),
        name: Value(e.name),
        color: Value(e.color),
      ),
    );

// ===== BOX MAPPING =====

/// Map Box database model to BoxEntity
BoxEntity mapBoxToEntity(Box box) => box.mapTo(
  (b) => BoxEntity(
    id: b.id,
    locationId: b.locationId,
    label: b.label,
  ),
);

/// Map BoxEntity to BoxesCompanion for database operations
BoxesCompanion mapBoxEntityToCompanion(BoxEntity entity) => entity.mapTo(
  (e) => BoxesCompanion(
    id: e.id == 0 ? const Value.absent() : Value(e.id),
    locationId: Value(e.locationId),
    label: Value(e.label),
  ),
);

// ===== ITEM MAPPING =====

/// Map Item database model to ItemEntity
ItemEntity mapItemToEntity(Item item) => item.mapTo(
  (i) => ItemEntity(
    id: i.id,
    boxId: i.boxId,
    locationId: i.locationId,
    name: i.name,
    quantity: i.quantity,
  ),
);

/// Map ItemEntity to ItemsCompanion for database operations
ItemsCompanion mapItemEntityToCompanion(ItemEntity entity) => entity.mapTo(
  (e) => ItemsCompanion(
    id: e.id == 0 ? const Value.absent() : Value(e.id),
    boxId: Value(e.boxId),
    locationId: Value(e.locationId),
    name: Value(e.name),
    quantity: Value(e.quantity),
  ),
);

// ===== CATEGORY MAPPING =====

/// Map Category database model to CategoryEntity
CategoryEntity mapCategoryToEntity(Category category) => category.mapTo(
  (c) => CategoryEntity(
    id: c.id,
    name: c.name,
    color: c.color,
  ),
);

/// Map CategoryEntity to CategoriesCompanion for database operations
CategoriesCompanion mapCategoryEntityToCompanion(CategoryEntity entity) =>
    entity.mapTo(
      (e) => CategoriesCompanion(
        id: e.id == 0 ? const Value.absent() : Value(e.id),
        name: Value(e.name),
        color: Value(e.color),
      ),
    );
