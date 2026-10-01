import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

enum UserRole { customer, admin }

@freezed
abstract class AppUser with _$AppUser {
  const AppUser._();

  const factory AppUser({
    required String uid,
    @Default('') String fullName,
    @Default('') String email,
    @Default('') String phone,
    @Default(UserRole.customer) UserRole role,
    @Default(false) bool blocked,
    String? photoUrl,
    @Default(<String, bool>{}) Map<String, bool> notificationPrefs,
    @TimestampConverter() DateTime? createdAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  bool get isAdmin => role == UserRole.admin;

  /// Best available label for greetings and headers.
  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    if (email.isNotEmpty) return email;
    return phone;
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
