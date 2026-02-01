import 'package:drift/drift.dart';

@DataClassName('Box')
class Boxes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get locationId =>
      integer().customConstraint('REFERENCES locations(id)')();
  TextColumn get label => text()();
}
