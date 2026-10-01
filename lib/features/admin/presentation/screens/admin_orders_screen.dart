import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/data/models/app_order.dart';
import '../../../orders/presentation/widgets/order_status.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_order_detail.dart';

const _filters = <(String?, String)>[
  (null, AppStrings.all),
  ('placed', AppStrings.statusPlaced),
  ('packed', AppStrings.statusPacked),
  ('shipped', AppStrings.statusShipped),
  ('outForDelivery', AppStrings.statusOutForDelivery),
  ('delivered', AppStrings.statusDelivered),
  ('returnRequested', AppStrings.statusReturnRequested),
  ('cancelled', AppStrings.statusCancelled),
];

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String? _status;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(adminOrdersProvider(_status));
    final dateFmt = DateFormat('d MMM, h:mm a');
    final q = _query.toLowerCase();

    return AdminPage(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Gap.m),
            child: Column(children: [
              AdminSearchField(
                hint: AppStrings.searchOrders,
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              const SizedBox(height: Gap.s),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final (value, label) in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: Gap.s),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _status == value,
                        onSelected: (_) => setState(() => _status = value),
                      ),
                    ),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: AdminAsyncList<AppOrder>(
              value: orders,
              emptyIcon: Icons.receipt_long_outlined,
              emptyMessage: AppStrings.noOrdersAdmin,
              onRetry: () => ref.invalidate(adminOrdersProvider),
              builder: (all) {
                final list = q.isEmpty
                    ? all
                    : all
                        .where((o) =>
                            o.orderNumber.toLowerCase().contains(q) ||
                            o.customerName.toLowerCase().contains(q) ||
                            o.customerPhone.contains(q))
                        .toList();
                if (list.isEmpty) {
                  return const Center(child: Text(AppStrings.noResults));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Gap.s),
                  itemBuilder: (context, i) {
                    final o = list[i];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        minTileHeight: 72,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AdminOrderDetail(orderId: o.id),
                        )),
                        title: Row(children: [
                          Text(o.orderNumber,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: Gap.s),
                          OrderStatusChip(status: o.status),
                        ]),
                        subtitle: Text(
                          '${o.customerName} · ${o.pricing.itemCount} ${AppStrings.items2}'
                          '${o.createdAt == null ? '' : ' · ${dateFmt.format(o.createdAt!)}'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(Money.format(o.pricing.grandTotal),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              o.paymentMethod == PaymentMethod.cod
                                  ? AppStrings.cashOnDelivery
                                  : paymentStatusLabel(o.paymentStatus),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
