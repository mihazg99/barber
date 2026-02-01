import 'package:drift/drift.dart';

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get boxId =>
      integer().nullable().customConstraint('REFERENCES boxes(id)')();
  IntColumn get locationId =>
      integer().nullable().customConstraint('REFERENCES locations(id)')();
  TextColumn get name => text()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
}
