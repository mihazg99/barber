import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:barber/features/brand_selection/data/models/user_brand_model.dart';

/// Remote data source for user_brands subcollection.
abstract class UserBrandsRemoteDataSource {
  Stream<List<UserBrandModel>> watchUserBrands(String userId);
  Future<UserBrandModel?> getUserBrand(String userId, String brandId);
  Future<void> createUserBrand(String userId, String brandId);
  Future<void> updateLoyaltyPoints(String userId, String brandId, int points);
  Future<void> updateLastActive(String userId, String brandId);
}

class UserBrandsRemoteDataSourceImpl implements UserBrandsRemoteDataSource {
  UserBrandsRemoteDataSourceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference _userBrandsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('user_brands');

  @override
  Stream<List<UserBrandModel>> watchUserBrands(String userId) {
    return _userBrandsRef(userId).snapshots().map(
      (snapshot) =>
          snapshot.docs
              .map((doc) => UserBrandModel.fromFirestore(doc))
              .toList(),
    );
  }

  @override
  Future<UserBrandModel?> getUserBrand(String userId, String brandId) async {
    final doc = await _userBrandsRef(userId).doc(brandId).get();
    if (!doc.exists) return null;
    return UserBrandModel.fromFirestore(doc);
  }

  @override
  Future<void> createUserBrand(String userId, String brandId) async {
    final userBrand = UserBrandModel(
      brandId: brandId,
      loyaltyPoints: 0,
      joinedAt: DateTime.now(),
      lastActive: DateTime.now(),
    );

    // Create user_brand document in subcollection
    // Note: We don't update the main user document's brand_id field
    // because it's a staff-managed field per security rules.
    // The app tracks the currently selected brand via lockedBrandIdProvider.
    await _userBrandsRef(userId).doc(brandId).set(userBrand.toFirestore());
  }

  @override
  Future<void> updateLoyaltyPoints(
    String userId,
    String brandId,
    int points,
  ) async {
    await _userBrandsRef(userId).doc(brandId).update({
      'loyalty_points': points,
      'last_active': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateLastActive(String userId, String brandId) async {
    await _userBrandsRef(userId).doc(brandId).update({
      'last_active': FieldValue.serverTimestamp(),
    });
  }
}
