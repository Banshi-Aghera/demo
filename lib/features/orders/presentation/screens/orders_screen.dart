import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/shell_tab_provider.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_status.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    final dateFmt = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.myOrders)),
      body: orders.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: [
            for (var i = 0; i < 3; i++) ...[const ShimmerBox(height: 110), const SizedBox(height: Gap.m)],
          ],
        ),
        error: (_, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: AppStrings.errGeneric,
          message: AppStrings.errNoInternet,
          actionLabel: AppStrings.retry,
          onAction: () => ref.invalidate(myOrdersProvider),
        ),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.receipt_long_outlined,
                title: AppStrings.noOrdersTitle,
                message: AppStrings.noOrdersBody,
                actionLabel: AppStrings.startShopping,
                onAction: () {
                  ref.read(shellTabStateProvider.notifier).select(ShellTab.home);
                  context.go(Routes.home);
                },
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myOrdersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.all(Gap.m),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Gap.m),
                  itemBuilder: (context, i) {
                    final o = list[i];
                    final first = o.items.isEmpty ? null : o.items.first;
                    final more = o.items.length - 1;
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push(Routes.orderPath(o.id)),
                        child: Padding(
                          padding: const EdgeInsets.all(Gap.m),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: AppNetworkImage(url: first?.imageUrl, width: 64, height: 64),
                              ),
                              const SizedBox(width: Gap.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(
                                        child: Text(o.orderNumber,
                                            style: const TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                      OrderStatusChip(status: o.status),
                                    ]),
                                    const SizedBox(height: Gap.xs),
                                    Text(
                                      first == null
                                          ? ''
                                          : more > 0
                                              ? '${first.name} +$more'
                                              : first.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: Gap.xs),
                                    Text(
                                      '${o.createdAt == null ? '' : dateFmt.format(o.createdAt!)} · ${Money.format(o.pricing.grandTotal)}',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
