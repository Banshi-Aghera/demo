import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_stat.freezed.dart';
part 'daily_stat.g.dart';

/// One document per IST day, maintained by Cloud Functions.
@freezed
abstract class DailyStat with _$DailyStat {
  const factory DailyStat({
    required String day,
    @Default(0) double revenue,
    @Default(0) int orders,
    @Default(0) int items,
    @Default(<String, int>{}) Map<String, int> productUnits,
  }) = _DailyStat;

  factory DailyStat.fromJson(Map<String, dynamic> json) =>
      _$DailyStatFromJson(json);
}
