import 'package:freezed_annotation/freezed_annotation.dart';

part 'pricing_settings.freezed.dart';
part 'pricing_settings.g.dart';

/// appSettings/pricing. Editable by admins in Phase 4; defaults apply until then.
@freezed
abstract class PricingSettings with _$PricingSettings {
  const factory PricingSettings({
    @Default(40) double deliveryFee,
    @Default(499) double freeDeliveryAbove,
    @Default(10000) double codMaxAmount,
  }) = _PricingSettings;

  factory PricingSettings.fromJson(Map<String, dynamic> json) =>
      _$PricingSettingsFromJson(json);
}
