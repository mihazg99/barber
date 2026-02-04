import 'package:equatable/equatable.dart';

import 'package:barber/features/auth/domain/entities/user_role.dart';

/// App user (client). doc_id: user_uid (Firebase Auth UID)
class UserEntity extends Equatable {
  const UserEntity({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.fcmToken,
    required this.brandId,
    required this.loyaltyPoints,
    this.role = UserRole.user,
  });

  final String userId;
  final String fullName;
  final String phone;
  final String fcmToken;
  final String brandId;

  /// Single loyalty card: points for this user (brand).
  final int loyaltyPoints;

  /// User role. Only [UserRole.user] can be self-assigned. barber/superadmin via Admin SDK.
  final UserRole role;

  UserEntity copyWith({
    String? userId,
    String? fullName,
    String? phone,
    String? fcmToken,
    String? brandId,
    int? loyaltyPoints,
    UserRole? role,
  }) =>
      UserEntity(
        userId: userId ?? this.userId,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        fcmToken: fcmToken ?? this.fcmToken,
        brandId: brandId ?? this.brandId,
        loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
        role: role ?? this.role,
      );

  @override
  List<Object?> get props => [
        userId,
        fullName,
        phone,
        fcmToken,
        brandId,
        loyaltyPoints,
        role,
      ];
}
