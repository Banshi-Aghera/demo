import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/app_exception.dart';
import '../../../catalog/data/models/product.dart';
import '../models/cart_item.dart';
import '../models/coupon.dart';
import '../models/pricing_settings.dart';

class CartRepository {
  CartRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _items(String uid) => _db
      .collection(FirestoreCollections.carts)
      .doc(uid)
      .collection(FirestoreCollections.items);

  Stream<List<CartItem>> watchCart(String uid) => _items(uid)
      .orderBy('addedAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map((d) => CartItem.fromJson({...d.data(), 'id': d.id}))
          .toList());

  /// Adds [quantity] of a product (or variant), capped at available stock.
  Future<void> addItem({
    required String uid,
    required Product product,
    ProductVariant? variant,
    int quantity = 1,
  }) async {
    final maxStock = product.stockFor(variant);
    if (maxStock <= 0) throw const AppException(AppStrings.errOutOfStock);

    final id = CartItem.idFor(product.id, variant?.id);
    final ref = _items(uid).doc(id);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final current = (snap.data()?['quantity'] as num?)?.toInt() ?? 0;
      final next = (current + quantity).clamp(1, maxStock).toInt();
      final item = CartItem(
        id: id,
        productId: product.id,
        variantId: variant?.id,
        variantLabel: variant?.label,
        name: product.name,
        imageUrl: product.thumbnail,
        unitPrice: product.priceFor(variant),
        mrp: product.mrpFor(variant),
        gstRate: product.gstRate,
        quantity: next,
        maxStock: maxStock,
      );
      tx.set(ref, {
        ...item.toJson(),
        'addedAt': snap.exists
            ? snap.data()!['addedAt']
            : FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> setQuantity(String uid, CartItem item, int quantity) {
    if (quantity <= 0) return remove(uid, item.id);
    final capped =
        item.maxStock > 0 ? quantity.clamp(1, item.maxStock).toInt() : quantity;
    return _items(uid).doc(item.id).update({'quantity': capped});
  }

  Future<void> remove(String uid, String itemId) =>
      _items(uid).doc(itemId).delete();

  Future<void> clear(String uid) async {
    final snap = await _items(uid).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  /// Removes from cart and saves to wishlist in one atomic write.
  Future<void> moveToWishlist(String uid, CartItem item) {
    final batch = _db.batch()
      ..delete(_items(uid).doc(item.id))
      ..set(
        _db
            .collection(FirestoreCollections.wishlists)
            .doc(uid)
            .collection(FirestoreCollections.items)
            .doc(item.productId),
        {'productId': item.productId, 'addedAt': FieldValue.serverTimestamp()},
      );
    return batch.commit();
  }

  /// Coupons are stored with the code as the document id, so customers can
  /// look up a code they know but can't list every coupon.
  Future<Coupon> findCoupon(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty || normalized.contains('/')) {
      throw const AppException(AppStrings.errCouponNotFound);
    }
    final doc = await _db
        .collection(FirestoreCollections.coupons)
        .doc(normalized)
        .get();
    if (!doc.exists) throw const AppException(AppStrings.errCouponNotFound);
    return Coupon.fromJson({...doc.data()!, 'id': doc.id});
  }

  Stream<PricingSettings> watchPricing() => _db
      .collection(FirestoreCollections.appSettings)
      .doc(FirestoreCollections.pricingDoc)
      .snapshots()
      .map((d) => d.exists
          ? PricingSettings.fromJson(d.data()!)
          : const PricingSettings());
}
