import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/providers/prefs_providers.dart';
import '../../data/models/product.dart';
import '../../data/models/product_category.dart';
import '../../data/models/promo_banner.dart';
import '../../data/models/review.dart';
import '../../data/repositories/catalog_repository.dart';
import '../../data/repositories/recently_viewed_repository.dart';
import '../../domain/product_filter.dart';

part 'catalog_providers.g.dart';

@Riverpod(keepAlive: true)
CatalogRepository catalogRepository(Ref ref) =>
    CatalogRepository(ref.watch(firebaseFirestoreProvider));

@Riverpod(keepAlive: true)
Stream<List<ProductCategory>> categories(Ref ref) =>
    ref.watch(catalogRepositoryProvider).watchCategories();

@riverpod
ProductCategory? categoryById(Ref ref, String id) {
  final list = ref.watch(categoriesProvider).value ?? const [];
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
}

@Riverpod(keepAlive: true)
Stream<List<PromoBanner>> banners(Ref ref) =>
    ref.watch(catalogRepositoryProvider).watchBanners();

@riverpod
Future<List<Product>> dealsOfTheDay(Ref ref) =>
    ref.watch(catalogRepositoryProvider).dealsOfTheDay();

@riverpod
Future<List<Product>> popularProducts(Ref ref) =>
    ref.watch(catalogRepositoryProvider).popular();

@riverpod
Stream<Product?> productById(Ref ref, String id) =>
    ref.watch(catalogRepositoryProvider).watchProduct(id);

@riverpod
Future<List<Product>> productsInCategory(Ref ref, String categoryId) =>
    ref.watch(catalogRepositoryProvider).productsInCategory(categoryId);

@riverpod
Future<List<Product>> relatedProducts(Ref ref, String productId) async {
  final product = await ref.watch(productByIdProvider(productId).future);
  if (product == null) return const [];
  return ref.watch(catalogRepositoryProvider).related(product);
}

@riverpod
Future<List<Review>> productReviews(Ref ref, String productId) =>
    ref.watch(catalogRepositoryProvider).reviews(productId);

@riverpod
Future<List<Product>> searchResults(Ref ref, String query) =>
    ref.watch(catalogRepositoryProvider).search(query);

/// Filter + sort state per category screen.
@riverpod
class CategoryFilter extends _$CategoryFilter {
  @override
  ProductFilter build(String categoryId) => const ProductFilter();

  void set(ProductFilter filter) => state = filter;
  void setSort(ProductSort sort) => state = state.copyWith(sort: sort);
  void clear() => state = state.cleared();
}

@riverpod
AsyncValue<List<Product>> filteredCategoryProducts(
    Ref ref, String categoryId) {
  final filter = ref.watch(categoryFilterProvider(categoryId));
  return ref
      .watch(productsInCategoryProvider(categoryId))
      .whenData(filter.apply);
}

// ---------- Recently viewed ----------

@Riverpod(keepAlive: true)
RecentlyViewedRepository recentlyViewedRepository(Ref ref) =>
    RecentlyViewedRepository(ref.watch(sharedPreferencesProvider));

@Riverpod(keepAlive: true)
class RecentlyViewedIds extends _$RecentlyViewedIds {
  @override
  List<String> build() => ref.watch(recentlyViewedRepositoryProvider).read();

  Future<void> record(String productId) async {
    state = await ref.read(recentlyViewedRepositoryProvider).add(productId);
  }
}

@riverpod
Future<List<Product>> recentlyViewedProducts(Ref ref) {
  final ids = ref.watch(recentlyViewedIdsProvider);
  return ref.watch(catalogRepositoryProvider).productsByIds(ids);
}
