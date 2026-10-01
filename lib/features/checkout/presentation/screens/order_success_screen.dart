import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/shell_tab_provider.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../orders/presentation/providers/orders_providers.dart';

class OrderSuccessScreen extends ConsumerWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderByIdProvider(orderId)).value;
    final theme = Theme.of(context);
    final savings = order == null
        ? 0.0
        : order.pricing.productDiscount + order.pricing.couponDiscount;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Gap.l),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    Lottie.asset(
                      'assets/animations/order_success.json',
                      width: 180,
                      height: 180,
                      repeat: false,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.check_circle_rounded,
                        size: 140,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: Gap.m),
                    Text(AppStrings.orderPlaced,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: Gap.s),
                    if (order != null)
                      Text('${AppStrings.orderNumberLabel}: ${order.orderNumber}',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    if (savings > 0) ...[
                      const SizedBox(height: Gap.l),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(Gap.m),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(Gap.radius),
                        ),
                        child: Row(children: [
                          const Icon(Icons.savings_rounded, color: Color(0xFFB45309)),
                          const SizedBox(width: Gap.s),
                          Expanded(
                            child: Text(
                              fill(AppStrings.youSavedOnOrder, {'amount': Money.format(savings)}),
                              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                            ),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: Gap.xl),
                    FilledButton(
                      onPressed: () => context.go(Routes.orderPath(orderId)),
                      child: const Text(AppStrings.viewOrder),
                    ),
                    const SizedBox(height: Gap.m),
                    OutlinedButton(
                      onPressed: () {
                        ref.read(shellTabStateProvider.notifier).select(ShellTab.home);
                        context.go(Routes.home);
                      },
                      child: const Text(AppStrings.continueShopping),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
