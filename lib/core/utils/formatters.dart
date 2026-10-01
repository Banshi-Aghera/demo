import 'package:intl/intl.dart';

class Money {
  Money._();

  static final _whole =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _paise =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  /// ₹1,299 for whole amounts, ₹1,299.50 otherwise.
  static String format(num amount) {
    final rounded = (amount * 100).round() / 100;
    return rounded == rounded.roundToDouble()
        ? _whole.format(rounded)
        : _paise.format(rounded);
  }
}

/// Replaces `{key}` placeholders in a string from AppStrings.
String fill(String template, Map<String, Object> values) {
  var out = template;
  values.forEach((k, v) => out = out.replaceAll('{$k}', '$v'));
  return out;
}

double round2(double v) => (v * 100).roundToDouble() / 100;
