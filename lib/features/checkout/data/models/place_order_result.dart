/// Response of the createOrder / retryPayment Cloud Functions.
class RazorpayCheckout {
  const RazorpayCheckout({
    required this.keyId,
    required this.orderId,
    required this.amountPaise,
    required this.name,
    required this.email,
    required this.contact,
  });

  factory RazorpayCheckout.fromMap(Map<String, dynamic> m) => RazorpayCheckout(
        keyId: m['keyId'] as String,
        orderId: m['orderId'] as String,
        amountPaise: (m['amountPaise'] as num).toInt(),
        name: (m['name'] as String?) ?? '',
        email: (m['email'] as String?) ?? '',
        contact: (m['contact'] as String?) ?? '',
      );

  final String keyId;
  final String orderId;
  final int amountPaise;
  final String name;
  final String email;
  final String contact;
}

class PlaceOrderResult {
  const PlaceOrderResult({
    required this.orderId,
    required this.orderNumber,
    required this.paymentMethod,
    required this.grandTotal,
    required this.totalSavings,
    this.razorpay,
  });

  factory PlaceOrderResult.fromMap(Map<String, dynamic> m) => PlaceOrderResult(
        orderId: m['orderId'] as String,
        orderNumber: m['orderNumber'] as String,
        paymentMethod: m['paymentMethod'] as String,
        grandTotal: (m['grandTotal'] as num).toDouble(),
        totalSavings: (m['totalSavings'] as num?)?.toDouble() ?? 0,
        razorpay: m['razorpay'] == null
            ? null
            : RazorpayCheckout.fromMap(
                Map<String, dynamic>.from(m['razorpay'] as Map)),
      );

  final String orderId;
  final String orderNumber;
  final String paymentMethod;
  final double grandTotal;
  final double totalSavings;
  final RazorpayCheckout? razorpay;
}
