import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/callable.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../cart/data/models/coupon.dart';
import '../../../cart/data/models/pricing_settings.dart';
import '../../../catalog/data/models/product.dart';
import '../../../catalog/data/models/product_category.dart';
import '../../../catalog/data/models/promo_banner.dart';
import '../../../catalog/data/repositories/catalog_repository.dart';
import '../../../orders/data/models/app_order.dart';
import '../../../society/data/models/society.dart';
import '../../../society/data/models/society_membership.dart';
import '../models/business_settings.dart';
import '../models/daily_stat.dart';

/// Everything the admin panel reads and writes. Money- and role-related
/// changes go through Cloud Functions; catalog edits are direct Firestore
/// writes allowed by the security rules for admins.
class AdminRepository {
  AdminRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  // ---------- Dashboard ----------

  /// Last [days] daily stat documents, oldest first, with gaps filled in.
  Future<List<DailyStat>> dailyStats(int days) async {
    final today = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final ids = [
      for (var i = days - 1; i >= 0; i--)
        _dayId(today.subtract(Duration(days: i))),
    ];
    final snaps = await Future.wait(
      ids.map((id) => _db.collection(FirestoreCollections.dailyStats).doc(id).get()),
    );
    return [
      for (var i = 0; i < ids.length; i++)
        snaps[i].exists
            ? DailyStat.fromJson({...snaps[i].data()!, 'day': ids[i]})
            : DailyStat(day: ids[i]),
    ];
  }

  static String _dayId(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<int> newUsersCount(int days) async {
    final since = Timestamp.fromDate(DateTime.now().subtract(Duration(days: days)));
    final snap = await _db
        .collection(FirestoreCollections.users)
        .where('createdAt', isGreaterThan: since)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<int> pendingOrdersCount() async {
    final snap = await _db
        .collection(FirestoreCollections.orders)
        .where('status', whereIn: ['placed', 'packed'])
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<List<Product>> lowStockProducts() async {
    final snap = await _db
        .collection(FirestoreCollections.products)
        .where('stock', isLessThanOrEqualTo: AppConstants.lowStockThreshold)
        .orderBy('stock')
        .limit(20)
        .get();
    return snap.docs
        .map((d) => Product.fromJson({...d.data(), 'id': d.id}))
        .where((p) => p.active && !p.hasVariants)
        .toList();
  }

  // ---------- Products ----------

  Stream<List<Product>> watchProducts() => _db
      .collection(FirestoreCollections.products)
      .orderBy('createdAt', descending: true)
      .limit(300)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Product.fromJson({...d.data(), 'id': d.id}))
          .toList());

  Future<void> saveProduct(Product product) {
    final col = _db.collection(FirestoreCollections.products);
    final ref = product.id.isEmpty ? col.doc() : col.doc(product.id);
    final data = product.toJson()
      ..remove('id')
      ..['nameLower'] = product.name.toLowerCase()
      ..['searchKeywords'] =
          CatalogRepository.buildKeywords(product.name, product.brand);
    if (product.createdAt == null) data['createdAt'] = FieldValue.serverTimestamp();
    return ref.set(data, SetOptions(merge: true));
  }

  Future<void> deleteProduct(String id) =>
      _db.collection(FirestoreCollections.products).doc(id).delete();

  // ---------- Categories and banners ----------

  Future<void> saveCategory(ProductCategory category) {
    final col = _db.collection(FirestoreCollections.categories);
    final ref = category.id.isEmpty ? col.doc() : col.doc(category.id);
    return ref.set(category.toJson()..remove('id'), SetOptions(merge: true));
  }

  Future<void> deleteCategory(String id) =>
      _db.collection(FirestoreCollections.categories).doc(id).delete();

  Future<void> saveBanner(PromoBanner banner) {
    final col = _db.collection(FirestoreCollections.banners);
    final ref = banner.id.isEmpty ? col.doc() : col.doc(banner.id);
    return ref.set(banner.toJson()..remove('id'), SetOptions(merge: true));
  }

  Future<void> deleteBanner(String id) =>
      _db.collection(FirestoreCollections.banners).doc(id).delete();

  // ---------- Orders ----------

  /// [status] null means every status.
  Stream<List<AppOrder>> watchOrders({String? status, int limit = 100}) {
    Query<Map<String, dynamic>> q = _db.collection(FirestoreCollections.orders);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AppOrder.fromJson({...d.data(), 'id': d.id}))
            .toList());
  }

  Future<List<AppOrder>> ordersBetween(DateTime from, DateTime to) async {
    final snap = await _db
        .collection(FirestoreCollections.orders)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('createdAt')
        .get();
    return snap.docs
        .map((d) => AppOrder.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) =>
      callFunction(_functions, 'adminUpdateOrderStatus',
          {'orderId': orderId, 'status': status});

  Future<void> resolveReturn(String orderId, bool approve, String reason) =>
      callFunction(_functions, 'adminResolveReturn',
          {'orderId': orderId, 'approve': approve, 'reason': reason});

  Future<void> retryRefund(String orderId) =>
      callFunction(_functions, 'adminRetryRefund', {'orderId': orderId});

  // ---------- Users ----------

  Stream<List<AppUser>> watchUsers({int limit = 300}) => _db
      .collection(FirestoreCollections.users)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs
          .map((d) => AppUser.fromJson({...d.data(), 'uid': d.id}))
          .toList());

  Future<void> setUserFlags(String userId, {bool? blocked, String? role}) =>
      callFunction(_functions, 'adminSetUserFlags', {
        'userId': userId,
        if (blocked != null) 'blocked': blocked,
        if (role != null) 'role': role,
      });

  Future<List<AppOrder>> ordersOfUser(String userId) async {
    final snap = await _db
        .collection(FirestoreCollections.orders)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snap.docs
        .map((d) => AppOrder.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  // ---------- Societies ----------

  Stream<List<Society>> watchSocieties() => _db
      .collection(FirestoreCollections.societies)
      .orderBy('nameLower')
      .snapshots()
      .map((s) => s.docs
          .map((d) => Society.fromJson({...d.data(), 'id': d.id}))
          .toList());

  /// Society codes must be unique: residents join by typing one.
  Future<bool> isCodeTaken(String code, String exceptId) async {
    final snap = await _db
        .collection(FirestoreCollections.societies)
        .where('code', isEqualTo: code.toUpperCase())
        .limit(2)
        .get();
    return snap.docs.any((d) => d.id != exceptId);
  }

  Future<void> saveSociety(Society society) {
    final col = _db.collection(FirestoreCollections.societies);
    final ref = society.id.isEmpty ? col.doc() : col.doc(society.id);
    final data = society.toJson()
      ..remove('id')
      ..['nameLower'] = society.name.toLowerCase()
      ..['code'] = society.code.toUpperCase();
    if (society.createdAt == null) data['createdAt'] = FieldValue.serverTimestamp();
    return ref.set(data, SetOptions(merge: true));
  }

  Future<void> deleteSociety(String id) =>
      _db.collection(FirestoreCollections.societies).doc(id).delete();

  Stream<List<SocietyMembership>> watchMemberships(String status) => _db
      .collection(FirestoreCollections.societyMemberships)
      .where('status', isEqualTo: status)
      .limit(200)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => SocietyMembership.fromJson(d.data())).toList());

  Future<void> setMembershipStatus(String userId, String status) => _db
          .collection(FirestoreCollections.societyMemberships)
          .doc(userId)
          .update({
        'status': status,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

  // ---------- Coupons ----------

  Stream<List<Coupon>> watchCoupons() => _db
      .collection(FirestoreCollections.coupons)
      .snapshots()
      .map((s) => s.docs
          .map((d) => Coupon.fromJson({...d.data(), 'id': d.id}))
          .toList());

  /// The document id is the code, so lookups stay a single read.
  Future<void> saveCoupon(Coupon coupon, {String? previousCode}) async {
    final code = coupon.code.toUpperCase();
    final col = _db.collection(FirestoreCollections.coupons);
    if (previousCode != null && previousCode != code) {
      await col.doc(previousCode).delete();
    }
    await col.doc(code).set(
          coupon.toJson()
            ..remove('id')
            ..['code'] = code,
          SetOptions(merge: true),
        );
  }

  Future<void> deleteCoupon(String code) =>
      _db.collection(FirestoreCollections.coupons).doc(code).delete();

  // ---------- Settings ----------

  Stream<BusinessSettings> watchBusiness() => _db
      .collection(FirestoreCollections.appSettings)
      .doc(FirestoreCollections.businessDoc)
      .snapshots()
      .map((d) => d.exists
          ? BusinessSettings.fromJson(d.data()!)
          : const BusinessSettings());

  Stream<RewardSettings> watchRewards() => _db
      .collection(FirestoreCollections.appSettings)
      .doc('rewards')
      .snapshots()
      .map((d) =>
          d.exists ? RewardSettings.fromJson(d.data()!) : const RewardSettings());

  Future<void> savePricing(PricingSettings s) => _db
      .collection(FirestoreCollections.appSettings)
      .doc(FirestoreCollections.pricingDoc)
      .set(s.toJson(), SetOptions(merge: true));

  Future<void> saveBusiness(BusinessSettings s) => _db
      .collection(FirestoreCollections.appSettings)
      .doc(FirestoreCollections.businessDoc)
      .set(s.toJson(), SetOptions(merge: true));

  Future<void> saveRewards(RewardSettings s) => _db
      .collection(FirestoreCollections.appSettings)
      .doc('rewards')
      .set(s.toJson(), SetOptions(merge: true));
}
