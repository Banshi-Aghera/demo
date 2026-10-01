import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../checkout/presentation/payment_flow.dart';
import '../../../checkout/presentation/providers/checkout_providers.dart';
import '../../data/invoice/invoice_pdf.dart';
import '../../data/models/app_order.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_status.dart';
import '../widgets/order_timeline.dart';
import '../widgets/review_sheet.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen>
    with AsyncActionMixin<OrderDetailScreen> {
  Future<void> _cancel(AppOrder order) async {
    final reason = TextEditingController();
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.cancelOrderTitle),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (order.paymentStatus == PaymentStatus.paid) const Text(AppStrings.cancelOrderBody),
          const SizedBox(height: Gap.m),
          TextField(
            controller: reason,
            maxLength: 300,
            decoration: const InputDecoration(hintText: AppStrings.cancelReasonHint),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.keepOrder)),
          FilledButton(
            style: FilledButton.styleFrom(
                minimumSize: const Size(120, 44), backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.cancelOrder),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (yes != true) return;
    final ok = await runAction('cancel',
        () => ref.read(ordersRepositoryProvider).cancel(order.id, text));
    if (ok && mounted) showInfoSnackBar(context, AppStrings.orderCancelled);
  }

  Future<void> _payNow(AppOrder order) async {
    await runAction('pay', () async {
      final result = await ref.read(checkoutRepositoryProvider).retryPayment(order.id);
      if (mounted) await runOnlinePayment(context, ref, result);
    });
  }

  Future<void> _invoice(AppOrder order) async {
    showInfoSnackBar(context, AppStrings.preparingInvoice);
    await runAction('invoice', () => InvoicePdf.share(order));
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    return orderAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.wifi_off_rounded,
          title: AppStrings.errGeneric,
          message: AppStrings.errNoInternet,
          actionLabel: AppStrings.retry,
          onAction: () => ref.invalidate(orderByIdProvider(widget.orderId)),
        ),
      ),
      data: (order) => order == null
          ? Scaffold(
              appBar: AppBar(),
              body: const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: AppStrings.noOrdersTitle,
                message: AppStrings.errGeneric,
              ),
            )
          : _buildOrder(order),
    );
  }

  Widget _buildOrder(AppOrder order) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');
    final canReturn = order.canRequestReturn(DateTime.now(), AppConstants.returnWindowDays);
    final p = order.pricing;

    Widget card(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: Gap.m),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: Gap.m),
                child,
              ]),
            ),
          ),
        );

    Widget row(String k, String v, {Color? color, bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(k, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null))),
            Text(v, style: TextStyle(color: color, fontWeight: bold ? FontWeight.w700 : null)),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: Text(order.orderNumber)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(Gap.m),
            children: [
              // Header + actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.m),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          '${AppStrings.placedOn} ${order.createdAt == null ? '' : dateFmt.format(order.createdAt!)}',
                          style: TextStyle(color: muted),
                        ),
                      ),
                      OrderStatusChip(status: order.status),
                    ]),
                    const SizedBox(height: Gap.l),
                    OrderTimeline(order: order),
                    if (order.returnRequest != null) ...[
                      const SizedBox(height: Gap.m),
                      Text('${AppStrings.cancelledReason}: ${_returnReasonLabel(order.returnRequest!.reason)}',
                          style: TextStyle(color: muted)),
                    ],
                    const SizedBox(height: Gap.m),
                    if (order.awaitingPayment)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.s),
                        child: PrimaryButton(
                          label: '${AppStrings.payNow} · ${Money.format(p.grandTotal)}',
                          loading: isBusy('pay'),
                          onPressed: isAnyBusy ? null : () => _payNow(order),
                        ),
                      ),
                    Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
                      if (order.canCancel)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                          onPressed: isAnyBusy ? null : () => _cancel(order),
                          icon: isBusy('cancel')
                              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.close_rounded),
                          label: const Text(AppStrings.cancelOrder),
                        ),
                      if (canReturn)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                          onPressed: () => context.push(Routes.orderReturnPath(order.id)),
                          icon: const Icon(Icons.assignment_return_outlined),
                          label: const Text(AppStrings.requestReturn),
                        ),
                      if (order.hasInvoice)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                          onPressed: isAnyBusy ? null : () => _invoice(order),
                          icon: isBusy('invoice')
                              ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text(AppStrings.downloadInvoice),
                        ),
                    ]),
                  ]),
                ),
              ),
              const SizedBox(height: Gap.m),

              card(
                '${AppStrings.itemsInOrder} (${p.itemCount})',
                Column(children: [
                  for (final l in order.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.m),
                      child: Row(children: [
                        InkWell(
                          onTap: () => context.push(Routes.productPath(l.productId)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AppNetworkImage(url: l.imageUrl, width: 56, height: 56),
                          ),
                        ),
                        const SizedBox(width: Gap.m),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text(
                              [if (l.variantLabel != null) l.variantLabel!, '× ${l.quantity}',
                                Money.format(l.lineTotal)].join('  ·  '),
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                          ]),
                        ),
                        if (order.canReview)
                          l.reviewed
                              ? Text(AppStrings.rated, style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600))
                              : TextButton.icon(
                                  onPressed: () => showReviewSheet(context, order, l),
                                  icon: const Icon(Icons.star_outline_rounded),
                                  label: const Text(AppStrings.rateItem),
                                ),
                      ]),
                    ),
                ]),
              ),

              card(
                AppStrings.deliveryAddress,
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(order.address.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(order.address.formatted, style: TextStyle(color: muted, height: 1.4)),
                  Text(order.address.phone, style: TextStyle(color: muted)),
                ]),
              ),

              card(
                AppStrings.priceDetails,
                Column(children: [
                  row(AppStrings.itemTotalMrp, Money.format(p.mrpTotal)),
                  if (p.productDiscount > 0)
                    row(AppStrings.productDiscount, '− ${Money.format(p.productDiscount)}', color: AppColors.success),
                  if (p.couponDiscount > 0)
                    row('${AppStrings.couponDiscount} (${p.couponCode})', '− ${Money.format(p.couponDiscount)}',
                        color: AppColors.success),
                  row(AppStrings.deliveryFee, p.deliveryFee == 0 ? AppStrings.free : Money.format(p.deliveryFee),
                      color: p.deliveryFee == 0 ? AppColors.success : null),
                  row(AppStrings.gstIncluded, Money.format(p.gstIncluded), color: muted),
                  const Divider(height: Gap.l),
                  row(AppStrings.grandTotal, Money.format(p.grandTotal), bold: true),
                  const SizedBox(height: Gap.s),
                  row(AppStrings.paymentLabel,
                      '${order.paymentMethod == PaymentMethod.cod ? AppStrings.cashOnDelivery : AppStrings.payOnline} · ${paymentStatusLabel(order.paymentStatus)}',
                      color: muted),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _returnReasonLabel(String code) => switch (code) {
      'damaged' => AppStrings.reasonDamaged,
      'wrongItem' => AppStrings.reasonWrongItem,
      'notAsDescribed' => AppStrings.reasonNotAsDescribed,
      'qualityIssue' => AppStrings.reasonQuality,
      _ => AppStrings.reasonOther,
    };
