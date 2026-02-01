import 'package:dartz/dartz.dart';
import 'package:barber/core/errors/failure.dart';
import 'package:barber/core/errors/firestore_failure.dart';
import 'package:barber/core/firebase/collections.dart';
import 'package:barber/features/brand/data/mappers/brand_firestore_mapper.dart';
import 'package:barber/features/brand/domain/entities/brand_entity.dart';
import 'package:barber/features/brand/domain/repositories/brand_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrandRepositoryImpl implements BrandRepository {
  BrandRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.brands);

  @override
  Future<Either<Failure, BrandEntity?>> getById(String brandId) async {
    try {
      final doc = await _col.doc(brandId).get();
      if (doc.data() == null) return const Right(null);
      return Right(BrandFirestoreMapper.fromFirestore(doc));
    } catch (e) {
      return Left(FirestoreFailure('Failed to get brand: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> set(BrandEntity entity) async {
    try {
      await _col.doc(entity.brandId).set(BrandFirestoreMapper.toFirestore(entity));
      return const Right(null);
    } catch (e) {
      return Left(FirestoreFailure('Failed to set brand: $e'));
    }
  }
}
