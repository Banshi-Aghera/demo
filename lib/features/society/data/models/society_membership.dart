import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';

part 'society_membership.freezed.dart';
part 'society_membership.g.dart';

enum MembershipStatus { pending, approved, rejected }

/// One document per user in `societyMemberships`, with id = user uid.
@freezed
abstract class SocietyMembership with _$SocietyMembership {
  const SocietyMembership._();

  const factory SocietyMembership({
    required String userId,
    required String societyId,
    required String societyName,
    required String wing,
    required String flatNumber,
    @Default(MembershipStatus.pending) MembershipStatus status,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? reviewedAt,
  }) = _SocietyMembership;

  factory SocietyMembership.fromJson(Map<String, dynamic> json) =>
      _$SocietyMembershipFromJson(json);

  bool get isApproved => status == MembershipStatus.approved;
  String get flatLabel => '$wing-$flatNumber';
}
