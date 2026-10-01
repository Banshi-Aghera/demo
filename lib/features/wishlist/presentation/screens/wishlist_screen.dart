import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../providers/wishlist_providers.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(wishlistProductsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.wishlist)),
      body: products.when(
        loading: () =>
            const CustomScrollView(slivers: [ProductGridSkeleton(count: 4)]),
        error: (_, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: AppStrings.errGeneric,
          message: AppStrings.errNoInternet,
          actionLabel: AppStrings.retry,
          onAction: () => ref.invalidate(wishlistProductsProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.favorite_border_rounded,
                title: AppStrings.wishlistEmptyTitle,
                message: AppStrings.wishlistEmptyBody,
              )
            : GridView.builder(
                padding: const EdgeInsets.all(Gap.m),
                gridDelegate: productGridDelegate,
                itemCount: list.length,
                itemBuilder: (context, i) => ProductCard(product: list[i]),
              ),
      ),
    );
  }
}
