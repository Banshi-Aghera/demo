import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/shell_tab_provider.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../catalog/data/models/product.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../catalog/presentation/widgets/banner_carousel.dart';
import '../../../catalog/presentation/widgets/product_card.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dealsOfTheDayProvider);
    ref.invalidate(popularProductsProvider);
    ref.invalidate(recentlyViewedProductsProvider);
    await Future.wait([
      ref.read(dealsOfTheDayProvider.future),
      ref.read(popularProductsProvider.future),
    ]).catchError((_) => const <List<Product>>[]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;
    final theme = Theme.of(context);
    final firstName = user?.fullName.trim().split(' ').first ?? '';

    final banners = ref.watch(bannersProvider);
    final categories = ref.watch(categoriesProvider);
    final deals = ref.watch(dealsOfTheDayProvider);
    final popular = ref.watch(popularProductsProvider);
    final recent = ref.watch(recentlyViewedProductsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    final nothingYet = (categories.value?.isEmpty ?? false) &&
        (popular.value?.isEmpty ?? false);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.s, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        firstName.isEmpty
                            ? AppStrings.helloGuest
                            : '${AppStrings.hello}, $firstName',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.notifications,
                      icon: Badge(
                        isLabelVisible: unread > 0,
                        label: Text('$unread'),
                        child: const Icon(Icons.notifications_none_rounded),
                      ),
                      onPressed: () => context.push(Routes.notifications),
                    ),
                    IconButton(
                      tooltip: AppStrings.wishlist,
                      icon: const Icon(Icons.favorite_border_rounded),
                      onPressed: () => context.push(Routes.wishlist),
                    ),
                  ],
                ),
              ),
            ),
            // Search bar (opens the search screen)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(Gap.m),
                child: Material(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(Gap.radius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Gap.radius),
                    onTap: () => context.push(Routes.search),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: Gap.m),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Gap.radius),
                        border:
                            Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: Gap.s),
                          Text(
                            AppStrings.searchHint,
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (nothingYet)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.storefront_rounded,
                  title: AppStrings.storeComingTitle,
                  message: AppStrings.storeComingBody,
                ),
              ),
            // Banners
            SliverToBoxAdapter(
              child: banners.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Gap.m),
                  child: AspectRatio(aspectRatio: 2.2, child: ShimmerBox()),
                ),
                error: (_, _) => const SizedBox.shrink(),
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink()
                    : BannerCarousel(banners: list),
              ),
            ),
            // Category chips
            SliverToBoxAdapter(
              child: categories.maybeWhen(
                data: (list) => list.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: AppStrings.shopByCategory,
                            onSeeAll: () => ref
                                .read(shellTabStateProvider.notifier)
                                .select(ShellTab.categories),
                          ),
                          SizedBox(
                            height: 48,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Gap.m),
                              itemCount: list.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: Gap.s),
                              itemBuilder: (context, i) => ActionChip(
                                label: Text(list[i].name),
                                onPressed: () => context
                                    .push(Routes.categoryPath(list[i].id)),
                              ),
                            ),
                          ),
                        ],
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            _railSliver(AppStrings.dealsOfTheDay, deals),
            _railSliver(AppStrings.popularNow, popular),
            _railSliver(AppStrings.recentlyViewed, recent, hideWhileLoading: true),
            const SliverToBoxAdapter(child: SizedBox(height: Gap.xl)),
          ],
        ),
      ),
    );
  }

  Widget _railSliver(String title, AsyncValue<List<Product>> value,
      {bool hideWhileLoading = false}) {
    return SliverToBoxAdapter(
      child: value.when(
        loading: () => hideWhileLoading
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: title),
                  const ProductRailSkeleton(),
                ],
              ),
        error: (_, _) => const SizedBox.shrink(),
        data: (list) => list.isEmpty
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: title),
                  ProductRail(products: list),
                ],
              ),
      ),
    );
  }
}
