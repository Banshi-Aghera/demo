import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/promo_banner.dart';
import '../models/review.dart';

class CatalogRepository {
  CatalogRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(FirestoreCollections.products);

  Product _toProduct(DocumentSnapshot<Map<String, dynamic>> d) =>
      Product.fromJson({...?d.data(), 'id': d.id});

  Stream<List<ProductCategory>> watchCategories() => _db
      .collection(FirestoreCollections.categories)
      .orderBy('sortOrder')
      .snapshots()
      .map((s) => s.docs
          .map((d) => ProductCategory.fromJson({...d.data(), 'id': d.id}))
          .where((c) => c.active)
          .toList());

  Stream<List<PromoBanner>> watchBanners() => _db
      .collection(FirestoreCollections.banners)
      .orderBy('sortOrder')
      .snapshots()
      .map((s) => s.docs
          .map((d) => PromoBanner.fromJson({...d.data(), 'id': d.id}))
          .where((b) => b.active)
          .toList());

  Stream<Product?> watchProduct(String id) => _products
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? _toProduct(d) : null);

  Future<List<Product>> productsInCategory(String categoryId) async {
    final snap = await _products
        .where('categoryId', isEqualTo: categoryId)
        .where('active', isEqualTo: true)
        .get();
    return snap.docs.map(_toProduct).toList();
  }

  Future<List<Product>> dealsOfTheDay() async {
    final snap = await _products
        .where('isDealOfDay', isEqualTo: true)
        .where('active', isEqualTo: true)
        .limit(AppConstants.homeRailLimit)
        .get();
    return snap.docs.map(_toProduct).toList();
  }

  /// Needs the composite index (active ASC, soldCount DESC) in
  /// firestore.indexes.json.
  Future<List<Product>> popular() async {
    final snap = await _products
        .where('active', isEqualTo: true)
        .orderBy('soldCount', descending: true)
        .limit(AppConstants.homeRailLimit)
        .get();
    return snap.docs.map(_toProduct).toList();
  }

  Future<List<Product>> related(Product product) async {
    final snap = await _products
        .where('categoryId', isEqualTo: product.categoryId)
        .where('active', isEqualTo: true)
        .limit(AppConstants.homeRailLimit + 1)
        .get();
    return snap.docs
        .map(_toProduct)
        .where((p) => p.id != product.id)
        .take(AppConstants.homeRailLimit)
        .toList();
  }

  /// Keeps the order of [ids]. Firestore allows 30 ids per whereIn.
  Future<List<Product>> productsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final found = <String, Product>{};
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snap =
          await _products.where(FieldPath.documentId, whereIn: chunk).get();
      for (final d in snap.docs) {
        found[d.id] = _toProduct(d);
      }
    }
    return [
      for (final id in ids)
        if (found[id]?.active == true) found[id]!,
    ];
  }

  /// Keyword search. Products store `searchKeywords` (lowercase word
  /// prefixes of name and brand, written by the admin product form and the
  /// seed script). The first word hits the index; the rest filter locally.
  /// For typo tolerance at scale, swap this for Algolia or Typesense.
  Future<List<Product>> search(String query) async {
    final words = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return const [];

    final snap = await _products
        .where('searchKeywords', arrayContains: words.first)
        .limit(60)
        .get();

    return snap.docs.map(_toProduct).where((p) {
      if (!p.active) return false;
      final haystack = '${p.name} ${p.brand}'.toLowerCase();
      return words.every(haystack.contains);
    }).toList();
  }

  /// Needs the composite index (productId ASC, createdAt DESC).
  Future<List<Review>> reviews(String productId) async {
    final snap = await _db
        .collection(FirestoreCollections.reviews)
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();
    return snap.docs
        .map((d) => Review.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  /// Builds prefix keywords for a product (used by admin form in Phase 4).
  static List<String> buildKeywords(String name, String brand) {
    final out = <String>{};
    for (final word in '$name $brand'.toLowerCase().split(RegExp(r'[^a-z0-9]+'))) {
      for (var i = 1; i <= word.length; i++) {
        out.add(word.substring(0, i));
      }
    }
    return out.toList();
  }
}
