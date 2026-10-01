import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../catalog/presentation/screens/image_viewer_screen.dart';
import '../../../orders/data/invoice/invoice_pdf.dart';
import '../../../orders/data/models/app_order.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../../../orders/presentation/widgets/order_status.dart';
import '../../../orders/presentation/widgets/order_timeline.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

/// Next status an admin can set, with its button label.
(String, String)? _nextStatus(OrderStatus s) => switch (s) {
      OrderStatus.placed => ('packed', AppStrings.markPacked),
      OrderStatus.packed => ('shipped', AppStrings.markShipped),
      OrderStatus.shipped => ('outForDelivery', AppStrings.markOutForDelivery),
      OrderStatus.outForDelivery => ('delivered', AppStrings.markDelivered),
      _ => null,
    };

class AdminOrderDetail extends ConsumerStatefulWidget {
  const AdminOrderDetail({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<AdminOrderDetail> createState() => _AdminOrderDetailState();
}

class _AdminOrderDetailState extends ConsumerState<AdminOrderDetail>
    with AsyncActionMixin<AdminOrderDetail> {
  Future<void> _advance(String status) async {
    final ok = await runAction(
      'status',
      () => ref.read(adminRepositoryProvider).updateOrderStatus(widget.orderId, status),
    );
    if (ok && mounted) showInfoSnackBar(context, AppStrings.statusUpdated);
  }

  Future<void> _resolveReturn(bool approve) async {
    var reason = '';
    if (!approve) {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(AppStrings.rejectReturn),
          content: TextField(
            controller: controller,
            maxLength: 300,
            decoration: const InputDecoration(labelText: AppStrings.rejectReason),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(AppStrings.cancel)),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(AppStrings.reject),
            ),
          ],
        ),
      );
      reason = controller.text.trim();
      controller.dispose();
      if (confirmed != true) return;
    } else {
      final yes = await confirmDialog(context,
          title: AppStrings.approveReturn,
          body: AppStrings.cancelOrderBody,
          confirmLabel: AppStrings.approve);
      if (!yes) return;
    }
    final ok = await runAction('return',
        () => ref.read(adminRepositoryProvider).resolveReturn(widget.orderId, approve, reason));
    if (ok && mounted) showInfoSnackBar(context, AppStrings.returnResolved);
  }

  Future<void> _retryRefund() async {
    final ok = await runAction(
        'refund', () => ref.read(adminRepositoryProvider).retryRefund(widget.orderId));
    if (ok && mounted) showInfoSnackBar(context, AppStrings.refundIssued);
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(title: Text(orderAsync.value?.orderNumber ?? AppStrings.orderDetails)),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: AppStrings.errGeneric,
          message: AppStrings.errNoInternet,
          actionLabel: AppStrings.retry,
          onAction: () => ref.invalidate(orderByIdProvider(widget.orderId)),
        ),
        data: (order) => order == null
            ? const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: AppStrings.noResults,
                message: AppStrings.errGeneric,
              )
            : _build(order),
      ),
    );
  }

  Widget _build(AppOrder order) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateFmt = DateFormat('d MMM yyyy, h:mm a');
    final next = _nextStatus(order.status);
    final p = order.pricing;

    return AdminPage(
      maxWidth: 820,
      child: ListView(
        padding: const EdgeInsets.all(Gap.m),
        children: [
          AdminSectionCard(
            title: AppStrings.status,
            trailing: OrderStatusChip(status: order.status),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                '${AppStrings.placedOn} ${order.createdAt == null ? '' : dateFmt.format(order.createdAt!)}',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: Gap.m),
              OrderTimeline(order: order),
              const SizedBox(height: Gap.m),
              Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
                if (next != null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: isAnyBusy ? null : () => _advance(next.$1),
                    icon: isBusy('status')
                        ? const SizedBox.square(
                            dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.arrow_forward_rounded),
                    label: Text(next.$2),
                  ),
                if (order.paymentStatus == PaymentStatus.refundPending)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: isAnyBusy ? null : _retryRefund,
                    icon: isBusy('refund')
                        ? const SizedBox.square(
                            dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh_rounded),
                    label: const Text(AppStrings.retryRefund),
                  ),
                if (order.hasInvoice)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: isAnyBusy ? null : () => runAction('pdf', () => InvoicePdf.share(order)),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text(AppStrings.downloadInvoice),
                  ),
              ]),
            ]),
          ),
          if (order.returnRequest != null) ...[
            const SizedBox(height: Gap.m),
            AdminSectionCard(
              title: AppStrings.returnRequestLabel,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_returnReason(order.returnRequest!.reason),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (order.returnRequest!.comment.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: Gap.xs),
                    child: Text(order.returnRequest!.comment),
                  ),
                if (order.returnRequest!.photoUrls.isNotEmpty) ...[
                  const SizedBox(height: Gap.s),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: order.returnRequest!.photoUrls.length,
                      separatorBuilder: (_, _) => const SizedBox(width: Gap.s),
                      itemBuilder: (context, i) => InkWell(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          fullscreenDialog: true,
                          builder: (_) => ImageViewerScreen(
                              images: order.returnRequest!.photoUrls, initialIndex: i),
                        )),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppNetworkImage(
                              url: order.returnRequest!.photoUrls[i], width: 72, height: 72),
                        ),
                      ),
                    ),
                  ),
                ],
                if (order.status == OrderStatus.returnRequested) ...[
                  const SizedBox(height: Gap.m),
                  Wrap(spacing: Gap.s, runSpacing: Gap.s, children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      onPressed: isAnyBusy ? null : () => _resolveReturn(true),
                      icon: isBusy('return')
                          ? const SizedBox.square(
                              dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_rounded),
                      label: const Text(AppStrings.approveReturn),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                      onPressed: isAnyBusy ? null : () => _resolveReturn(false),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text(AppStrings.rejectReturn),
                    ),
                  ]),
                ],
              ]),
            ),
          ],
          const SizedBox(height: Gap.m),
          AdminSectionCard(
            title: AppStrings.customer,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (order.customerPhone.isNotEmpty) Text(order.customerPhone, style: TextStyle(color: muted)),
              if (order.customerEmail.isNotEmpty) Text(order.customerEmail, style: TextStyle(color: muted)),
              const Divider(height: Gap.l),
              Text(AppStrings.deliveryAddress, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(order.address.formatted, style: TextStyle(color: muted, height: 1.4)),
            ]),
          ),
          const SizedBox(height: Gap.m),
          AdminSectionCard(
            title: '${AppStrings.itemsInOrder} (${p.itemCount})',
            child: Column(children: [
              for (final l in order.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: Gap.s),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppNetworkImage(url: l.imageUrl, width: 44, height: 44),
                    ),
                    const SizedBox(width: Gap.m),
                    Expanded(
                      child: Text(
                        l.variantLabel == null ? l.name : '${l.name} (${l.variantLabel})',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('× ${l.quantity}', style: TextStyle(color: muted)),
                    const SizedBox(width: Gap.m),
                    Text(Money.format(l.lineTotal),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ),
              const Divider(height: Gap.l),
              _row(AppStrings.subtotalLabel, Money.format(p.subtotal)),
              if (p.couponDiscount > 0)
                _row('${AppStrings.couponDiscount} (${p.couponCode})',
                    '− ${Money.format(p.couponDiscount)}', color: AppColors.success),
              _row(AppStrings.deliveryFee,
                  p.deliveryFee == 0 ? AppStrings.free : Money.format(p.deliveryFee)),
              _row(AppStrings.gstIncluded, Money.format(p.gstIncluded), color: muted),
              const Divider(height: Gap.l),
              _row(AppStrings.grandTotal, Money.format(p.grandTotal), bold: true),
              const SizedBox(height: Gap.s),
              _row(
                AppStrings.paymentLabel,
                '${order.paymentMethod == PaymentMethod.cod ? AppStrings.cashOnDelivery : AppStrings.payOnline} · ${paymentStatusLabel(order.paymentStatus)}',
                color: muted,
              ),
            ]),
          ),
          const SizedBox(height: Gap.xl),
        ],
      ),
    );
  }

  Widget _row(String k, String v, {Color? color, bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(k, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null))),
          Text(v, style: TextStyle(color: color, fontWeight: bold ? FontWeight.w700 : null)),
        ]),
      );
}

String _returnReason(String code) => switch (code) {
      'damaged' => AppStrings.reasonDamaged,
      'wrongItem' => AppStrings.reasonWrongItem,
      'notAsDescribed' => AppStrings.reasonNotAsDescribed,
      'qualityIssue' => AppStrings.reasonQuality,
      _ => AppStrings.reasonOther,
    };
