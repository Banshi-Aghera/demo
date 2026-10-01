import 'package:freezed_annotation/freezed_annotation.dart';

part 'promo_banner.freezed.dart';
part 'promo_banner.g.dart';

/// Home carousel banner managed by admins. Tapping opens a category or
/// product when a target is set.
@freezed
abstract class PromoBanner with _$PromoBanner {
  const factory PromoBanner({
    required String id,
    required String imageUrl,
    @Default('') String title,
    @Default('') String subtitle,
    String? targetCategoryId,
    String? targetProductId,
    @Default(0) int sortOrder,
    @Default(true) bool active,
  }) = _PromoBanner;

  factory PromoBanner.fromJson(Map<String, dynamic> json) =>
      _$PromoBannerFromJson(json);
}
