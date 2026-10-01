import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_category.freezed.dart';
part 'product_category.g.dart';

@freezed
abstract class ProductCategory with _$ProductCategory {
  const factory ProductCategory({
    required String id,
    required String name,
    @Default('') String imageUrl,
    @Default(0) int sortOrder,
    @Default(true) bool active,
  }) = _ProductCategory;

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      _$ProductCategoryFromJson(json);
}
