import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/features/services/domain/entities/service_entity.dart';

abstract class ServiceRepository {
  /// Fetches all services for a brand.
  Future<Either<Failure, List<ServiceEntity>>> getByBrandId(String brandId);

  /// Fetches a service by id.
  Future<Either<Failure, ServiceEntity?>> getById(String serviceId);

  /// Creates or overwrites a service. doc_id = [entity.serviceId].
  Future<Either<Failure, void>> set(ServiceEntity entity);

  /// Deletes a service by id.
  Future<Either<Failure, void>> delete(String serviceId);
}
