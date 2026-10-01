import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/app_order.dart';

String orderStatusLabel(OrderStatus s) => switch (s) {
      OrderStatus.pendingPayment => AppStrings.statusPendingPayment,
      OrderStatus.placed => AppStrings.statusPlaced,
      OrderStatus.packed => AppStrings.statusPacked,
      OrderStatus.shipped => AppStrings.statusShipped,
      OrderStatus.outForDelivery => AppStrings.statusOutForDelivery,
      OrderStatus.delivered => AppStrings.statusDelivered,
      OrderStatus.cancelled => AppStrings.statusCancelled,
      OrderStatus.returnRequested => AppStrings.statusReturnRequested,
      OrderStatus.returned => AppStrings.statusReturned,
    };

String paymentStatusLabel(PaymentStatus s) => switch (s) {
      PaymentStatus.pending => AppStrings.payStatusPending,
      PaymentStatus.paid => AppStrings.payStatusPaid,
      PaymentStatus.failed => AppStrings.payStatusFailed,
      PaymentStatus.refunded => AppStrings.payStatusRefunded,
      PaymentStatus.refundPending => AppStrings.payStatusRefundPending,
      PaymentStatus.codPending => AppStrings.payStatusCodPending,
      PaymentStatus.codCollected => AppStrings.payStatusCodCollected,
    };

Color orderStatusColor(OrderStatus s, ColorScheme scheme) => switch (s) {
      OrderStatus.pendingPayment => AppColors.warning,
      OrderStatus.delivered => AppColors.success,
      OrderStatus.cancelled => AppColors.danger,
      OrderStatus.returnRequested || OrderStatus.returned => AppColors.warning,
      _ => scheme.primary,
    };

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = orderStatusColor(status, Theme.of(context).colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
