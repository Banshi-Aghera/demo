import '../../../core/constants/app_strings.dart';
import '../data/models/product.dart';

enum ProductSort {
  newest(AppStrings.sortNewest),
  priceLowHigh(AppStrings.sortPriceLowHigh),
  priceHighLow(AppStrings.sortPriceHighLow),
  popular(AppStrings.sortPopular);

  const ProductSort(this.label);
  final String label;
}

/// Client-side filter and sort for a product list.
class ProductFilter {
  const ProductFilter({
    this.minPrice,
    this.maxPrice,
    this.brands = const {},
    this.minRating = 0,
    this.sort = ProductSort.popular,
  });

  final double? minPrice;
  final double? maxPrice;
  final Set<String> brands;
  final double minRating;
  final ProductSort sort;

  /// Number of filters applied (sort not counted), for the badge.
  int get activeCount =>
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (brands.isNotEmpty ? 1 : 0) +
      (minRating > 0 ? 1 : 0);

  ProductFilter copyWith({
    double? minPrice,
    double? maxPrice,
    bool clearPrice = false,
    Set<String>? brands,
    double? minRating,
    ProductSort? sort,
  }) {
    return ProductFilter(
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      brands: brands ?? this.brands,
      minRating: minRating ?? this.minRating,
      sort: sort ?? this.sort,
    );
  }

  ProductFilter cleared() => ProductFilter(sort: sort);

  List<Product> apply(List<Product> input) {
    final out = input.where((p) {
      final price = p.displayPrice;
      if (minPrice != null && price < minPrice!) return false;
      if (maxPrice != null && price > maxPrice!) return false;
      if (brands.isNotEmpty && !brands.contains(p.brand)) return false;
      if (minRating > 0 && p.ratingAvg < minRating) return false;
      return true;
    }).toList();

    switch (sort) {
      case ProductSort.newest:
        out.sort((a, b) => (b.createdAt ?? DateTime(2000))
            .compareTo(a.createdAt ?? DateTime(2000)));
      case ProductSort.priceLowHigh:
        out.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
      case ProductSort.priceHighLow:
        out.sort((a, b) => b.displayPrice.compareTo(a.displayPrice));
      case ProductSort.popular:
        out.sort((a, b) => b.soldCount.compareTo(a.soldCount));
    }
    // Out-of-stock items always go last.
    out.sort((a, b) => (a.inStock ? 0 : 1).compareTo(b.inStock ? 0 : 1));
    return out;
  }
}
