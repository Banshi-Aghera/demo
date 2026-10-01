import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/address.dart';

class AddressRepository {
  AddressRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _db
      .collection(FirestoreCollections.users)
      .doc(uid)
      .collection(FirestoreCollections.addresses);

  /// Default address first.
  Stream<List<Address>> watch(String uid) => _col(uid).snapshots().map((s) {
        final list = s.docs
            .map((d) => Address.fromJson({...d.data(), 'id': d.id}))
            .toList();
        list.sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
        return list;
      });

  /// Creates (empty id) or updates an address. The first address, or one
  /// marked default, becomes the only default.
  Future<String> save(String uid, Address address) async {
    final existing = await _col(uid).get();
    final makeDefault = address.isDefault || existing.docs.isEmpty;
    final ref =
        address.id.isEmpty ? _col(uid).doc() : _col(uid).doc(address.id);
    final data = address.copyWith(id: ref.id, isDefault: makeDefault).toJson()
      ..remove('id');

    final batch = _db.batch();
    if (makeDefault) {
      for (final d in existing.docs) {
        if (d.id != ref.id && d.data()['isDefault'] == true) {
          batch.update(d.reference, {'isDefault': false});
        }
      }
    }
    batch.set(ref, data);
    await batch.commit();
    return ref.id;
  }

  /// Deleting the default promotes another address to default.
  Future<void> delete(String uid, Address address) async {
    final batch = _db.batch()..delete(_col(uid).doc(address.id));
    if (address.isDefault) {
      final others = await _col(uid).limit(2).get();
      for (final d in others.docs) {
        if (d.id != address.id) {
          batch.update(d.reference, {'isDefault': true});
          break;
        }
      }
    }
    await batch.commit();
  }
}
