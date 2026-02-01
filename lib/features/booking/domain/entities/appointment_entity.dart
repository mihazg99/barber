import 'package:equatable/equatable.dart';

/// Status values for [AppointmentEntity.status].
abstract final class AppointmentStatus {
  static const String scheduled = 'scheduled';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String noShow = 'no_show';
}

/// Detailed record of a booking. doc_id: appointment_id
class AppointmentEntity extends Equatable {
  const AppointmentEntity({
    required this.appointmentId,
    required this.brandId,
    required this.locationId,
    required this.userId,
    required this.barberId,
    required this.serviceIds,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    this.createdAt,
  });

  final String appointmentId;
  final String brandId;
  final String locationId;
  final String userId;
  final String barberId;
  final List<String> serviceIds;
  final DateTime startTime;
  final DateTime endTime;
  final num totalPrice;
  final String status;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        appointmentId,
        brandId,
        locationId,
        userId,
        barberId,
        serviceIds,
        startTime,
        endTime,
        totalPrice,
        status,
        createdAt,
      ];
}
