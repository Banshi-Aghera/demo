import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/society.dart';
import '../models/society_membership.dart';

class SocietyRepository {
  SocietyRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _societies =>
      _db.collection(FirestoreCollections.societies);
  CollectionReference<Map<String, dynamic>> get _memberships =>
      _db.collection(FirestoreCollections.societyMemberships);

  Society _toSociety(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Society.fromJson({...?doc.data(), 'id': doc.id});

  /// Prefix search on the lowercase name field.
  Future<List<Society>> searchByName(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];
    final snap = await _societies
        .orderBy('nameLower')
        .startAt([q])
        .endAt(['$q\uf8ff'])
        .limit(20)
        .get();
    return snap.docs.map(_toSociety).toList();
  }

  Future<Society?> findByCode(String code) async {
    final snap = await _societies
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return _toSociety(snap.docs.first);
  }

  Stream<SocietyMembership?> watchMembership(String uid) {
    return _memberships.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return SocietyMembership.fromJson(data);
    });
  }

  /// Creates or replaces the user's membership request as "pending".
  Future<void> requestMembership({
    required String uid,
    required Society society,
    required String wing,
    required String flatNumber,
  }) {
    final membership = SocietyMembership(
      userId: uid,
      societyId: society.id,
      societyName: society.name,
      wing: wing.trim().toUpperCase(),
      flatNumber: flatNumber.trim().toUpperCase(),
    );
    return _memberships.doc(uid).set({
      ...membership.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
    });
  }

  // --- Group Buys ---
  
  CollectionReference<Map<String, dynamic>> get _groupDeals =>
      _db.collection('groupDeals');

  Stream<List<Map<String, dynamic>>> watchGroupDeals(String societyId) {
    return _groupDeals
        .where('societyId', isEqualTo: societyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> createGroupDeal(Map<String, dynamic> dealData) async {
    dealData['createdAt'] = FieldValue.serverTimestamp();
    await _groupDeals.add(dealData);
  }

  Future<void> joinGroupDeal(String dealId, String userId) async {
    await _groupDeals.doc(dealId).update({
      'participantIds': FieldValue.arrayUnion([userId]),
    });
  }
}
