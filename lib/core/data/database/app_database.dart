import 'package:drift/drift.dart';
import 'package:barber/core/data/database/connection/connection_helper.dart';

import 'package:barber/features/inventory/data/models/item_table.dart';
import 'package:barber/features/inventory/data/models/box_table.dart';
import 'package:barber/features/inventory/data/models/location_table.dart';
import 'package:barber/features/inventory/data/models/category_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Locations, Boxes, Items, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 3;

  // define DAO or convenience queries here
}
