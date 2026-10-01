import 'package:freezed_annotation/freezed_annotation.dart';

part 'address.freezed.dart';
part 'address.g.dart';

enum AddressLabel { home, work, other }

/// Stored at users/{uid}/addresses/{id}.
@freezed
abstract class Address with _$Address {
  const Address._();

  const factory Address({
    required String id,
    @Default(AddressLabel.home) AddressLabel label,
    required String fullName,
    required String phone,
    required String line1,
    @Default('') String line2,
    @Default('') String landmark,
    required String city,
    required String state,
    required String stateCode,
    required String pincode,
    @Default(false) bool isDefault,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  /// Multi-line text for cards and invoices.
  String get formatted => [
        line1,
        if (line2.isNotEmpty) line2,
        if (landmark.isNotEmpty) landmark,
        '$city, $state $pincode',
      ].join('\n');
}
