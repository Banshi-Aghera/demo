import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../providers/catalog_providers.dart';

class CategoriesTab extends ConsumerWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    const grid = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 180,
      mainAxisSpacing: Gap.m,
      crossAxisSpacing: Gap.m,
      childAspectRatio: 0.85,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navCategories),
        actions: [
          IconButton(
            tooltip: AppStrings.searchHint,
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push(Routes.search),
          ),
        ],
      ),
      body: categories.when(
        loading: () => GridView.builder(
          padding: const EdgeInsets.all(Gap.m),
          gridDelegate: grid,
          itemCount: 6,
          itemBuilder: (_, _) => const ShimmerBox(),
        ),
        error: (_, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: AppStrings.errGeneric,
          message: AppStrings.errNoInternet,
          actionLabel: AppStrings.retry,
          onAction: () => ref.invalidate(categoriesProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.grid_view_rounded,
                title: AppStrings.noProductsTitle,
                message: AppStrings.noCategories,
              )
            : GridView.builder(
                padding: const EdgeInsets.all(Gap.m),
                gridDelegate: grid,
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final c = list[i];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push(Routes.categoryPath(c.id)),
                      child: Column(
                        children: [
                          Expanded(child: AppNetworkImage(url: c.imageUrl)),
                          Padding(
                            padding: const EdgeInsets.all(Gap.s + 4),
                            child: Text(
                              c.name,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
