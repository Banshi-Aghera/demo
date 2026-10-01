import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/services/callable.dart';
import '../models/place_order_result.dart';

/// Talks to the order Cloud Functions. The server prices everything.
class CheckoutRepository {
  CheckoutRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<PlaceOrderResult> placeOrder({
    required String addressId,
    required String paymentMethod,
    String? couponCode,
    String deliveryOption = 'standard',
  }) async {
    final data = await callFunction(_functions, 'createOrder', {
      'addressId': addressId,
      'paymentMethod': paymentMethod,
      'couponCode': couponCode,
      'deliveryOption': deliveryOption,
    });
    return PlaceOrderResult.fromMap(data);
  }

  Future<PlaceOrderResult> retryPayment(String orderId) async {
    final data =
        await callFunction(_functions, 'retryPayment', {'orderId': orderId});
    return PlaceOrderResult.fromMap(data);
  }

  /// Returns 'paid', or 'refunded' if the order had already expired.
  Future<String> verifyPayment({
    required String orderId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final data = await callFunction(_functions, 'verifyPayment', {
      'orderId': orderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySignature': razorpaySignature,
    });
    return (data['status'] as String?) ?? 'paid';
  }
}
