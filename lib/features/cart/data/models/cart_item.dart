import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';

part 'cart_item.freezed.dart';
part 'cart_item.g.dart';

/// Stored at carts/{uid}/items/{id}, where id = productId or
/// productId__variantId. Prices are a snapshot; the server re-prices at
/// checkout (Phase 3).
@freezed
abstract class CartItem with _$CartItem {
  const CartItem._();

  const factory CartItem({
    required String id,
    required String productId,
    String? variantId,
    String? variantLabel,
    required String name,
    String? imageUrl,
    required double unitPrice,
    required double mrp,
    @Default(18) double gstRate,
    @Default(1) int quantity,
    @Default(0) int maxStock,
    @TimestampConverter() DateTime? addedAt,
  }) = _CartItem;

  factory CartItem.fromJson(Map<String, dynamic> json) =>
      _$CartItemFromJson(json);

  static String idFor(String productId, String? variantId) =>
      variantId == null ? productId : '${productId}__$variantId';

  double get lineTotal => unitPrice * quantity;
  double get lineMrp => mrp * quantity;
}
