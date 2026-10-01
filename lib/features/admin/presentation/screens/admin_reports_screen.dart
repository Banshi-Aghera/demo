import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../orders/data/models/app_order.dart';
import '../../../orders/presentation/widgets/order_status.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen>
    with AsyncActionMixin<AdminReportsScreen> {
  late DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  Future<List<AppOrder>> _load() async {
    final from = DateTime(_range.start.year, _range.start.month, _range.start.day);
    final to = DateTime(_range.end.year, _range.end.month, _range.end.day, 23, 59, 59);
    final orders = await ref.read(adminRepositoryProvider).ordersBetween(from, to);
    if (orders.isEmpty) throw const AppException(AppStrings.noDataToExport);
    return orders;
  }

  Future<void> _save(String name, List<List<Object?>> rows) async {
    final csv = const ListToCsvConverter().convert(rows);
    // UTF-8 BOM so Excel shows ₹ and Indian names correctly.
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    await FileSaver.instance.saveFile(
      name: '$name-$stamp.csv',
      bytes: bytes,
      mimeType: MimeType.csv,
    );
  }

  Future<void> _exportOrders() async {
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final ok = await runAction('orders', () async {
      final orders = await _load();
      final rows = <List<Object?>>[
        [
          'Order number', 'Invoice number', 'Date', 'Customer', 'Phone', 'City',
          'State', 'Status', 'Payment method', 'Payment status', 'Items',
          'Item total', 'Product discount', 'Coupon', 'Coupon discount',
          'Delivery fee', 'GST included', 'Grand total',
        ],
        for (final o in orders)
          [
            o.orderNumber, o.invoiceNumber,
            o.createdAt == null ? '' : dateFmt.format(o.createdAt!),
            o.customerName, o.customerPhone, o.address.city, o.address.state,
            orderStatusLabel(o.status),
            o.paymentMethod == PaymentMethod.cod ? 'COD' : 'Online',
            paymentStatusLabel(o.paymentStatus),
            o.pricing.itemCount, o.pricing.subtotal, o.pricing.productDiscount,
            o.pricing.couponCode ?? '', o.pricing.couponDiscount,
            o.pricing.deliveryFee, o.pricing.gstIncluded, o.pricing.grandTotal,
          ],
      ];
      await _save('societycart-orders', rows);
    });
    if (ok && mounted) showInfoSnackBar(context, AppStrings.exportReady);
  }

  Future<void> _exportSales() async {
    final ok = await runAction('sales', () async {
      final orders = await _load();
      // Only orders that actually count as sales.
      final counted = orders.where((o) => const {
            OrderStatus.placed, OrderStatus.packed, OrderStatus.shipped,
            OrderStatus.outForDelivery, OrderStatus.delivered,
          }.contains(o.status));

      final units = <String, int>{};
      final revenue = <String, double>{};
      final names = <String, String>{};
      for (final o in counted) {
        for (final l in o.items) {
          final key = l.variantId == null ? l.productId : '${l.productId}__${l.variantId}';
          names[key] = l.variantLabel == null ? l.name : '${l.name} (${l.variantLabel})';
          units[key] = (units[key] ?? 0) + l.quantity;
          revenue[key] = (revenue[key] ?? 0) + l.netAmount;
        }
      }
      final keys = units.keys.toList()
        ..sort((a, b) => units[b]!.compareTo(units[a]!));
      final rows = <List<Object?>>[
        ['Product', 'Product ID', 'Units sold', 'Net revenue'],
        for (final k in keys) [names[k], k, units[k], revenue[k]!.toStringAsFixed(2)],
      ];
      await _save('societycart-product-sales', rows);
    });
    if (ok && mounted) showInfoSnackBar(context, AppStrings.exportReady);
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    return AdminPage(
      maxWidth: 700,
      child: ListView(
        padding: const EdgeInsets.all(Gap.m),
        children: [
          AdminSectionCard(
            title: AppStrings.dateRange,
            child: Column(children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range_rounded),
                title: Text('${dateFmt.format(_range.start)}  →  ${dateFmt.format(_range.end)}'),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      initialDateRange: _range,
                    );
                    if (picked != null) setState(() => _range = picked);
                  },
                  child: const Text(AppStrings.change),
                ),
              ),
              const SizedBox(height: Gap.m),
              PrimaryButton(
                label: AppStrings.exportOrders,
                icon: Icons.download_rounded,
                loading: isBusy('orders'),
                onPressed: isAnyBusy ? null : _exportOrders,
              ),
              const SizedBox(height: Gap.s),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: isAnyBusy ? null : _exportSales,
                icon: isBusy('sales')
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.insert_chart_outlined_rounded),
                label: const Text(AppStrings.exportSales),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
