import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:inventory/features/inventory/data/models/item_table.dart';
import 'package:inventory/features/inventory/data/models/box_table.dart';
import 'package:inventory/features/inventory/data/models/location_table.dart';
import 'package:inventory/features/inventory/data/models/category_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Locations, Boxes, Items, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  // define DAO or convenience queries here
}

LazyDatabase _openConnection() {
  if (Platform.isAndroid || Platform.isIOS) {
    return LazyDatabase(() async {
      return SqfliteQueryExecutor.inDatabaseFolder(path: 'app.sqlite');
    });
  }
  // For desktop and tests
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'app.sqlite'));
    return NativeDatabase(file);
  });
}
