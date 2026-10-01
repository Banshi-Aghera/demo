import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
abstract class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required String id,
    required String label,
    required double price,
    required double mrp,
    @Default(0) int stock,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantFromJson(json);
}

/// Prices are GST-inclusive rupees, as is standard for Indian retail.
@freezed
abstract class Product with _$Product {
  const Product._();

  const factory Product({
    required String id,
    required String name,
    @Default('') String nameLower,
    @Default('') String description,
    @Default('') String brand,
    required String categoryId,
    @Default(<String>[]) List<String> images,
    required double price,
    required double mrp,
    @Default(0) int stock,
    @Default(18) double gstRate,
    @Default('') String variantLabel,
    @Default(<ProductVariant>[]) List<ProductVariant> variants,
    @Default(0) double ratingAvg,
    @Default(0) int ratingCount,
    @Default(0) int soldCount,
    @Default(false) bool isDealOfDay,
    @Default(true) bool active,
    @Default(<String>[]) List<String> searchKeywords,
    @TimestampConverter() DateTime? createdAt,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  String? get thumbnail => images.isEmpty ? null : images.first;
  bool get hasVariants => variants.isNotEmpty;

  ProductVariant? variantById(String? id) {
    if (id == null) return null;
    for (final v in variants) {
      if (v.id == id) return v;
    }
    return null;
  }

  double priceFor(ProductVariant? v) => v?.price ?? price;
  double mrpFor(ProductVariant? v) => v?.mrp ?? mrp;
  int stockFor(ProductVariant? v) =>
      v?.stock ?? (hasVariants ? variants.fold(0, (a, b) => a + b.stock) : stock);

  int discountPercentFor(ProductVariant? v) {
    final m = mrpFor(v);
    final p = priceFor(v);
    if (m <= 0 || p >= m) return 0;
    return (((m - p) / m) * 100).round();
  }

  /// Lowest selling price across variants, used for list cards and sorting.
  double get displayPrice => hasVariants
      ? variants.map((v) => v.price).reduce((a, b) => a < b ? a : b)
      : price;

  double get displayMrp {
    if (!hasVariants) return mrp;
    final cheapest = variants.reduce((a, b) => a.price <= b.price ? a : b);
    return cheapest.mrp;
  }

  int get displayDiscountPercent {
    if (displayMrp <= 0 || displayPrice >= displayMrp) return 0;
    return (((displayMrp - displayPrice) / displayMrp) * 100).round();
  }

  bool get inStock => stockFor(null) > 0;
}
