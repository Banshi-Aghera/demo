import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';

class WishlistRepository {
  WishlistRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _items(String uid) => _db
      .collection(FirestoreCollections.wishlists)
      .doc(uid)
      .collection(FirestoreCollections.items);

  /// Product ids, newest first.
  Stream<List<String>> watchIds(String uid) => _items(uid)
      .orderBy('addedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toList());

  /// Returns true when the product is now in the wishlist.
  Future<bool> toggle(String uid, String productId) async {
    final ref = _items(uid).doc(productId);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
      return false;
    }
    await ref.set({
      'productId': productId,
      'addedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }
}
