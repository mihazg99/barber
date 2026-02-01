import 'package:equatable/equatable.dart';

class ItemEntity extends Equatable {
  final int id;
  final int? boxId;
  final int? locationId;
  final String name;
  final int quantity;

  const ItemEntity({
    required this.id,
    this.boxId,
    this.locationId,
    required this.name,
    required this.quantity,
  });

  @override
  List<Object?> get props => [id, boxId, locationId, name, quantity];

  @override
  String toString() =>
      'ItemEntity(id: $id, boxId: $boxId, locationId: $locationId, name: $name, quantity: $quantity)';
}
