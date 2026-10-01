import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/error/error_mapper.dart';
import '../../../core/router/routes.dart';
import '../../../core/utils/snackbars.dart';
import '../data/models/place_order_result.dart';
import '../data/repositories/razorpay_service.dart';
import 'providers/checkout_providers.dart';

/// Runs Razorpay for [result] and verifies on the server. Used by checkout
/// and by "Pay now" on an unpaid order. Navigates to the success screen when
/// paid; otherwise offers retry or opens the saved order.
Future<void> runOnlinePayment(
  BuildContext context,
  WidgetRef ref,
  PlaceOrderResult result, {
  ValueChanged<bool>? onVerifying,
}) async {
  final checkout = result.razorpay!;
  final outcome = await ref
      .read(razorpayServiceProvider)
      .pay(checkout, description: '${AppStrings.orderNo} ${result.orderNumber}');
  if (!context.mounted) return;

  switch (outcome) {
    case PaymentSuccess(:final paymentId, :final orderId, :final signature):
      onVerifying?.call(true);
      try {
        await ref.read(checkoutRepositoryProvider).verifyPayment(
              orderId: result.orderId,
              razorpayPaymentId: paymentId,
              razorpayOrderId: orderId,
              razorpaySignature: signature,
            );
        if (context.mounted) context.go(Routes.orderSuccessPath(result.orderId));
      } catch (e) {
        // The webhook will still confirm a genuine payment; show the order.
        if (!context.mounted) return;
        showErrorSnackBar(context, ErrorMapper.message(e) ?? AppStrings.errGeneric);
        context.go(Routes.orderPath(result.orderId));
      } finally {
        onVerifying?.call(false);
      }
    case PaymentCancelled():
      await _offerRetry(context, ref, result, AppStrings.paymentCancelled);
    case PaymentFailed(:final message):
      await _offerRetry(context, ref, result, message);
  }
}

Future<void> _offerRetry(
  BuildContext context,
  WidgetRef ref,
  PlaceOrderResult result,
  String message,
) async {
  final retry = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text(AppStrings.paymentFailedTitle),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(AppStrings.payLater),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text(AppStrings.retryPayment),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (retry == true) {
    await runOnlinePayment(context, ref, result);
  } else {
    context.go(Routes.orderPath(result.orderId));
  }
}
