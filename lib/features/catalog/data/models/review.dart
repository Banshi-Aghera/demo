import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';

part 'review.freezed.dart';
part 'review.g.dart';

@freezed
abstract class Review with _$Review {
  const factory Review({
    required String id,
    required String productId,
    required String userId,
    @Default('') String userName,
    required int rating,
    @Default('') String comment,
    @Default(<String>[]) List<String> imageUrls,
    @TimestampConverter() DateTime? createdAt,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
}
