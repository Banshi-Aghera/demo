import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/app_notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreCollections.notifications);

  /// Needs the composite index (userId ASC, createdAt DESC).
  Stream<List<AppNotification>> watch(String uid) => _col
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs
          .map((d) => AppNotification.fromJson({...d.data(), 'id': d.id}))
          .toList());

  Future<void> markRead(String id) => _col.doc(id).update({'read': true});

  Future<void> markAllRead(List<AppNotification> list) async {
    final batch = _db.batch();
    for (final n in list.where((n) => !n.read)) {
      batch.update(_col.doc(n.id), {'read': true});
    }
    await batch.commit();
  }

  Future<void> saveToken(String uid, String token, String platform) => _db
          .collection(FirestoreCollections.users)
          .doc(uid)
          .collection(FirestoreCollections.fcmTokens)
          .doc(token)
          .set({
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteToken(String uid, String token) => _db
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.fcmTokens)
      .doc(token)
      .delete();

  Future<void> setPreference(String uid, String key, bool enabled) => _db
      .collection(FirestoreCollections.users)
      .doc(uid)
      .update({'notificationPrefs.$key': enabled});
}
