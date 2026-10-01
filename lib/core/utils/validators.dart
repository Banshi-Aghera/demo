import '../constants/app_strings.dart';

class Validators {
  Validators._();

  static final _emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$');
  static final _indianMobile = RegExp(r'^[6-9]\d{9}$');
  static final _hasDigit = RegExp(r'\d');

  static String? required(String? value) =>
      (value == null || value.trim().isEmpty) ? AppStrings.errRequired : null;

  static String? fullName(String? value) =>
      (value == null || value.trim().length < 2) ? AppStrings.errNameShort : null;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    return _emailRegex.hasMatch(v) ? null : AppStrings.errEmail;
  }

  /// Expects 10 digits without the +91 prefix.
  static String? indianPhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\s'), '');
    return _indianMobile.hasMatch(digits) ? null : AppStrings.errPhone;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.length < 8) return AppStrings.errPasswordLength;
    if (!_hasDigit.hasMatch(v)) return AppStrings.errPasswordNumber;
    return null;
  }

  /// Login only checks that a password was typed; strength rules apply at sign-up.
  static String? loginPassword(String? value) =>
      (value == null || value.isEmpty) ? AppStrings.errRequired : null;

  static String? confirmPassword(String? value, String original) =>
      value == original ? null : AppStrings.errPasswordMatch;

  static String? otp(String? value) =>
      RegExp(r'^\d{6}$').hasMatch(value?.trim() ?? '') ? null : AppStrings.errOtp;

  static String? pincode(String? value) =>
      RegExp(r'^[1-9]\d{5}$').hasMatch(value?.trim() ?? '')
          ? null
          : AppStrings.errPincode;
}
