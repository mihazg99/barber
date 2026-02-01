import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final int id;
  final String name;
  final String color;

  const LocationEntity({
    required this.id,
    required this.name,
    required this.color,
  });

  @override
  List<Object?> get props => [id, name, color];

  @override
  String toString() => 'LocationEntity(id: $id, name: $name, color: $color)';
}
