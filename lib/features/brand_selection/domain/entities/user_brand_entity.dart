import 'package:equatable/equatable.dart';

/// User's membership in a specific brand with loyalty points.
class UserBrandEntity extends Equatable {
  const UserBrandEntity({
    required this.brandId,
    required this.loyaltyPoints,
    required this.joinedAt,
    required this.lastActive,
  });

  final String brandId;
  final int loyaltyPoints;
  final DateTime joinedAt;
  final DateTime lastActive;

  UserBrandEntity copyWith({
    String? brandId,
    int? loyaltyPoints,
    DateTime? joinedAt,
    DateTime? lastActive,
  }) => UserBrandEntity(
    brandId: brandId ?? this.brandId,
    loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    joinedAt: joinedAt ?? this.joinedAt,
    lastActive: lastActive ?? this.lastActive,
  );

  @override
  List<Object?> get props => [brandId, loyaltyPoints, joinedAt, lastActive];
}
