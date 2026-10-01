/// "Rupees One Thousand Two Hundred Sixty Six and Thirty Paise Only",
/// using the Indian system (thousand, lakh, crore).
String amountInWords(double amount) {
  final rupees = amount.floor();
  final paise = ((amount - rupees) * 100).round();
  final buffer = StringBuffer('Rupees ${_indian(rupees)}');
  if (paise > 0) buffer.write(' and ${_below100(paise)} Paise');
  buffer.write(' Only');
  return buffer.toString();
}

const _ones = [
  '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
  'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
  'Seventeen', 'Eighteen', 'Nineteen',
];
const _tens = [
  '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety',
];

String _below100(int n) {
  if (n < 20) return _ones[n];
  final rest = n % 10;
  return rest == 0 ? _tens[n ~/ 10] : '${_tens[n ~/ 10]} ${_ones[rest]}';
}

String _below1000(int n) {
  final h = n ~/ 100;
  final r = n % 100;
  if (h == 0) return _below100(r);
  return r == 0 ? '${_ones[h]} Hundred' : '${_ones[h]} Hundred ${_below100(r)}';
}

String _indian(int n) {
  if (n == 0) return 'Zero';
  final parts = <String>[];
  final crore = n ~/ 10000000;
  n %= 10000000;
  final lakh = n ~/ 100000;
  n %= 100000;
  final thousand = n ~/ 1000;
  n %= 1000;
  if (crore > 0) parts.add('${_indian(crore)} Crore');
  if (lakh > 0) parts.add('${_below100(lakh)} Lakh');
  if (thousand > 0) parts.add('${_below100(thousand)} Thousand');
  if (n > 0) parts.add(_below1000(n));
  return parts.join(' ');
}
