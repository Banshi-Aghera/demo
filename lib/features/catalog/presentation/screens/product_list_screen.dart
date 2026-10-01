import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../domain/product_filter.dart';
import '../providers/catalog_providers.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/product_card.dart';

/// Products in one category, with filters and sorting.
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ref.watch(categoryByIdProvider(categoryId));
    final filter = ref.watch(categoryFilterProvider(categoryId));
    final all = ref.watch(productsInCategoryProvider(categoryId));
    final filtered = ref.watch(filteredCategoryProductsProvider(categoryId));
    final notifier = ref.read(categoryFilterProvider(categoryId).notifier);

    Future<void> openFilters() async {
      final products = all.value;
      if (products == null) return;
      final result = await showFilterSheet(context,
          current: filter, products: products);
      if (result != null) notifier.set(result);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(category?.name ?? ''),
        actions: [
          PopupMenuButton<ProductSort>(
            tooltip: AppStrings.sortBy,
            icon: const Icon(Icons.sort_rounded),
            initialValue: filter.sort,
            onSelected: notifier.setSort,
            itemBuilder: (_) => [
              for (final s in ProductSort.values)
                PopupMenuItem(value: s, child: Text(s.label)),
            ],
          ),
          IconButton(
            tooltip: AppStrings.filters,
            onPressed: openFilters,
            icon: Badge(
              isLabelVisible: filter.activeCount > 0,
              label: Text('${filter.activeCount}'),
              child: const Icon(Icons.tune_rounded),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(productsInCategoryProvider(categoryId).future),
        child: CustomScrollView(
          slivers: [
            ...filtered.when(
              loading: () => [const ProductGridSkeleton()],
              error: (_, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: AppStrings.errGeneric,
                    message: AppStrings.errNoInternet,
                    actionLabel: AppStrings.retry,
                    onAction: () =>
                        ref.invalidate(productsInCategoryProvider(categoryId)),
                  ),
                ),
              ],
              data: (list) {
                if (list.isEmpty) {
                  final filtersOn = filter.activeCount > 0;
                  return [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: AppStrings.noProductsTitle,
                        message: filtersOn
                            ? AppStrings.noProductsMatchFilters
                            : AppStrings.noProductsInCategory,
                        actionLabel: filtersOn ? AppStrings.clearFilters : null,
                        onAction: filtersOn ? notifier.clear : null,
                      ),
                    ),
                  ];
                }
                return [
                  SliverPadding(
                    padding: const EdgeInsets.all(Gap.m),
                    sliver: SliverGrid(
                      gridDelegate: productGridDelegate,
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => ProductCard(product: list[i]),
                        childCount: list.length,
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}
