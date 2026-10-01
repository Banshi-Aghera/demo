import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/callable.dart';
import '../models/app_order.dart';

class OrdersRepository {
  OrdersRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(FirestoreCollections.orders);

  AppOrder _toOrder(DocumentSnapshot<Map<String, dynamic>> d) =>
      AppOrder.fromJson({...?d.data(), 'id': d.id});

  /// Needs the composite index (userId ASC, createdAt DESC).
  Stream<List<AppOrder>> watchMyOrders(String uid) => _orders
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map(_toOrder).toList());

  Stream<AppOrder?> watchOrder(String id) =>
      _orders.doc(id).snapshots().map((d) => d.exists ? _toOrder(d) : null);

  Future<void> cancel(String orderId, String reason) =>
      callFunction(_functions, 'cancelOrder', {
        'orderId': orderId,
        'reason': reason,
      });

  Future<void> requestReturn({
    required String orderId,
    required String reason,
    required String comment,
    required List<String> photoUrls,
  }) =>
      callFunction(_functions, 'requestReturn', {
        'orderId': orderId,
        'reason': reason,
        'comment': comment,
        'photoUrls': photoUrls,
      });

  Future<void> submitReview({
    required String orderId,
    required String productId,
    required int rating,
    required String comment,
    required List<String> imageUrls,
  }) =>
      callFunction(_functions, 'submitReview', {
        'orderId': orderId,
        'productId': productId,
        'rating': rating,
        'comment': comment,
        'imageUrls': imageUrls,
      });
}
