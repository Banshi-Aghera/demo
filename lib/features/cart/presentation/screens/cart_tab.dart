import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/shell_tab_provider.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../providers/cart_providers.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/coupon_card.dart';
import '../widgets/price_summary_card.dart';

class CartTab extends ConsumerWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartItemsProvider);
    final summary = ref.watch(cartSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(summary.itemCount == 0
            ? AppStrings.navCart
            : '${AppStrings.navCart} (${summary.itemCount} ${summary.itemCount == 1 ? AppStrings.item : AppStrings.items})'),
      ),
      body: items.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: const [
            ShimmerBox(height: 140),
            SizedBox(height: Gap.m),
            ShimmerBox(height: 140),
          ],
        ),
        error: (_, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: AppStrings.errGeneric,
          message: AppStrings.errNoInternet,
          actionLabel: AppStrings.retry,
          onAction: () => ref.invalidate(cartItemsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: AppStrings.cartEmptyTitle,
              message: AppStrings.cartEmptyBody,
              actionLabel: AppStrings.startShopping,
              onAction: () => ref
                  .read(shellTabStateProvider.notifier)
                  .select(ShellTab.home),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(Gap.m),
                children: [
                  _FreeDeliveryHint(remaining: summary.amountForFreeDelivery),
                  for (final item in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.m),
                      child: CartItemTile(key: ValueKey(item.id), item: item),
                    ),
                  CouponCard(couponError: summary.couponError),
                  const SizedBox(height: Gap.m),
                  PriceSummaryCard(summary: summary),
                  const SizedBox(height: Gap.xl),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: (items.value?.isEmpty ?? true)
          ? null
          : Material(
              elevation: 8,
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.m),
                  child: Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(Money.format(summary.grandTotal),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(AppStrings.grandTotal,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(width: Gap.m),
                      Expanded(
                        child: FilledButton(
                          onPressed: summary.couponError != null
                              ? () => showErrorSnackBar(context, summary.couponError!)
                              : () => context.push(Routes.checkout),
                          child: const Text(AppStrings.proceedToCheckout),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _FreeDeliveryHint extends StatelessWidget {
  const _FreeDeliveryHint({required this.remaining});

  final double remaining;

  @override
  Widget build(BuildContext context) {
    final free = remaining <= 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.m),
      child: Container(
        padding: const EdgeInsets.all(Gap.s + 4),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(Gap.radius),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_shipping_rounded, color: Color(0xFFB45309)),
            const SizedBox(width: Gap.s),
            Expanded(
              child: Text(
                free
                    ? AppStrings.freeDeliveryUnlocked
                    : fill(AppStrings.addMoreForFreeDelivery,
                        {'amount': Money.format(remaining)}),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
