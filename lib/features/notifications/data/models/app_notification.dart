import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String userId,
    required String title,
    @Default('') String body,
    @Default('order') String type,
    String? orderId,
    @Default(false) bool read,
    @TimestampConverter() DateTime? createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}
