import 'package:freezed_annotation/freezed_annotation.dart';

part 'business_settings.freezed.dart';
part 'business_settings.g.dart';

/// appSettings/business — printed on GST invoices.
@freezed
abstract class BusinessSettings with _$BusinessSettings {
  const factory BusinessSettings({
    @Default('') String legalName,
    @Default('') String gstin,
    @Default('') String addressLine,
    @Default('') String city,
    @Default('') String state,
    @Default('') String stateCode,
    @Default('') String pincode,
    @Default('') String email,
    @Default('') String phone,
  }) = _BusinessSettings;

  factory BusinessSettings.fromJson(Map<String, dynamic> json) =>
      _$BusinessSettingsFromJson(json);
}

/// appSettings/rewards — used by Neighbour Drop and Lending.
@freezed
abstract class RewardSettings with _$RewardSettings {
  const factory RewardSettings({
    @Default(10) int pointsPerParcel,
    @Default(10) int pointsPerRupee,
    @Default(10) double lendingFeePercent,
    @Default(3) int minOrdersPerSlot,
  }) = _RewardSettings;

  factory RewardSettings.fromJson(Map<String, dynamic> json) =>
      _$RewardSettingsFromJson(json);
}
