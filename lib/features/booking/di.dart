import 'package:barber/core/di.dart';
import 'package:barber/features/booking/data/repositories/availability_repository_impl.dart';
import 'package:barber/features/booking/data/repositories/appointment_repository_impl.dart';
import 'package:barber/features/booking/domain/repositories/availability_repository.dart';
import 'package:barber/features/booking/domain/repositories/appointment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return AvailabilityRepositoryImpl(firestore);
});

final appointmentRepositoryProvider = Provider<AppointmentRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return AppointmentRepositoryImpl(firestore);
});
