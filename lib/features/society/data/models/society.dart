import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';

part 'society.freezed.dart';
part 'society.g.dart';

@freezed
abstract class Society with _$Society {
  const factory Society({
    required String id,
    required String name,
    @Default('') String nameLower,
    @Default('') String address,
    @Default('') String city,
    required String code,
    @Default(false) bool securityDeskIsDefaultReceiver,
    @TimestampConverter() DateTime? createdAt,
  }) = _Society;

  factory Society.fromJson(Map<String, dynamic> json) =>
      _$SocietyFromJson(json);
}
