import 'package:drift/drift.dart';
import 'app_database.dart';
import 'package:barber/features/inventory/data/models/box_table.dart';
import 'package:barber/features/inventory/data/models/item_table.dart';
import 'package:barber/features/inventory/domain/entities/box_entity.dart';
import 'package:barber/features/inventory/domain/entities/item_entity.dart';

part 'box_dao.g.dart';

@DriftAccessor(tables: [Boxes, Items])
class BoxDao extends DatabaseAccessor<AppDatabase> with _$BoxDaoMixin {
  BoxDao(AppDatabase db) : super(db);

  // Fetch all boxes with their items
  Future<List<BoxEntity>> getAllBoxesWithItems() async {
    final boxRows = await select(boxes).get();
    final itemRows = await select(items).get();
    return boxRows.map((boxRow) {
      final boxItems =
          itemRows.where((item) => item.boxId == boxRow.id).toList();
      return BoxEntity(
        id: boxRow.id,
        locationId: boxRow.locationId,
        label: boxRow.label,
        items:
            boxItems
                .map(
                  (item) => ItemEntity(
                    id: item.id,
                    boxId: item.boxId,
                    name: item.name,
                    quantity: item.quantity,
                  ),
                )
                .toList(),
      );
    }).toList();
  }
}
