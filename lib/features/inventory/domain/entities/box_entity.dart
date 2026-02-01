import 'package:equatable/equatable.dart';
import 'item_entity.dart';

class BoxEntity extends Equatable {
  final int id;
  final int locationId;
  final String label;
  final List<ItemEntity> items;

  const BoxEntity({
    required this.id,
    required this.locationId,
    required this.label,
    this.items = const [],
  });

  @override
  List<Object?> get props => [id, locationId, label, items];

  @override
  String toString() =>
      'BoxEntity(id: $id, locationId: $locationId, label: $label, items: $items)';
}
