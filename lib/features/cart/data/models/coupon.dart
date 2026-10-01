import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/timestamp_converter.dart';

part 'coupon.freezed.dart';
part 'coupon.g.dart';

enum CouponType { percent, flat }

@freezed
abstract class Coupon with _$Coupon {
  const Coupon._();

  const factory Coupon({
    required String id,
    required String code,
    @Default(CouponType.percent) CouponType type,
    required double value,
    @Default(0) double minOrder,
    double? maxDiscount,
    @TimestampConverter() DateTime? expiresAt,
    @Default(0) int usageLimit,
    @Default(0) int usedCount,
    @Default(true) bool active,
  }) = _Coupon;

  factory Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);

  /// Returns a user-facing reason the coupon can't be used, or null.
  String? validate(double subtotal, {DateTime? now}) {
    final at = now ?? DateTime.now();
    if (!active) return AppStrings.errCouponInvalid;
    if (expiresAt != null && at.isAfter(expiresAt!)) {
      return AppStrings.errCouponExpired;
    }
    if (usageLimit > 0 && usedCount >= usageLimit) {
      return AppStrings.errCouponUsedUp;
    }
    if (subtotal < minOrder) {
      return fill(AppStrings.errCouponMinOrder,
          {'amount': Money.format(minOrder)});
    }
    return null;
  }

  double discountFor(double subtotal) {
    final raw = type == CouponType.percent ? subtotal * value / 100 : value;
    final capped =
        (maxDiscount != null && maxDiscount! > 0) ? min(raw, maxDiscount!) : raw;
    return min(capped, subtotal);
  }

  String get summary => type == CouponType.percent
      ? '${value.toStringAsFixed(0)}% ${AppStrings.off}'
      : '${Money.format(value)} ${AppStrings.off}';
}
