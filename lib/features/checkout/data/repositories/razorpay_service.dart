import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/place_order_result.dart';

sealed class PaymentOutcome {
  const PaymentOutcome();
}

class PaymentSuccess extends PaymentOutcome {
  const PaymentSuccess(this.paymentId, this.orderId, this.signature);
  final String paymentId;
  final String orderId;
  final String signature;
}

class PaymentCancelled extends PaymentOutcome {
  const PaymentCancelled();
}

class PaymentFailed extends PaymentOutcome {
  const PaymentFailed(this.message);
  final String message;
}

/// Opens Razorpay Checkout (Android/iOS) and waits for the result.
class RazorpayService {
  Future<PaymentOutcome> pay(RazorpayCheckout c, {required String description}) {
    final razorpay = Razorpay();
    final completer = Completer<PaymentOutcome>();

    void finish(PaymentOutcome outcome) {
      if (!completer.isCompleted) completer.complete(outcome);
      razorpay.clear();
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      if (r.paymentId == null || r.orderId == null || r.signature == null) {
        finish(const PaymentFailed(AppStrings.errGeneric));
      } else {
        finish(PaymentSuccess(r.paymentId!, r.orderId!, r.signature!));
      }
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      finish(r.code == Razorpay.PAYMENT_CANCELLED
          ? const PaymentCancelled()
          : PaymentFailed(r.message ?? AppStrings.errGeneric));
    });
    // External wallets (e.g. Paytm app) still end in success or error above.
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {});

    final hex = AppColors.primary.toARGB32().toRadixString(16).substring(2);
    razorpay.open({
      'key': c.keyId,
      'order_id': c.orderId,
      'amount': c.amountPaise,
      'currency': 'INR',
      'name': AppStrings.appName,
      'description': description,
      'prefill': {'name': c.name, 'email': c.email, 'contact': c.contact},
      'theme': {'color': '#$hex'},
    });
    return completer.future;
  }
}
