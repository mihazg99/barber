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
