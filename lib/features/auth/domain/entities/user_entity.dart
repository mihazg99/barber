import 'package:equatable/equatable.dart';

/// App user (client). doc_id: user_uid (Firebase Auth UID)
class UserEntity extends Equatable {
  const UserEntity({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.fcmToken,
    required this.brandId,
    required this.loyaltyPoints,
  });

  final String userId;
  final String fullName;
  final String phone;
  final String fcmToken;
  final String brandId;

  /// Single loyalty card: points for this user (brand).
  final int loyaltyPoints;

  UserEntity copyWith({
    String? userId,
    String? fullName,
    String? phone,
    String? fcmToken,
    String? brandId,
    int? loyaltyPoints,
  }) => UserEntity(
    userId: userId ?? this.userId,
    fullName: fullName ?? this.fullName,
    phone: phone ?? this.phone,
    fcmToken: fcmToken ?? this.fcmToken,
    brandId: brandId ?? this.brandId,
    loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
  );

  @override
  List<Object?> get props => [
    userId,
    fullName,
    phone,
    fcmToken,
    brandId,
    loyaltyPoints,
  ];
}
