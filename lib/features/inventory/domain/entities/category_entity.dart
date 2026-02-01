import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final int id;
  final String name;
  final String color;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.color,
  });

  @override
  List<Object?> get props => [id, name, color];

  @override
  String toString() => 'CategoryEntity(id: $id, name: $name, color: $color)';
}
