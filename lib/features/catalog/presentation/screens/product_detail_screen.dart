import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/providers/shell_tab_provider.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/price_tag.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/models/product.dart';
import '../../data/models/review.dart';
import '../providers/catalog_providers.dart';
import '../widgets/product_card.dart';
import '../widgets/wishlist_button.dart';
import 'image_viewer_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with AsyncActionMixin<ProductDetailScreen> {
  String? _variantId;
  int _quantity = 1;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(recentlyViewedIdsProvider.notifier).record(widget.productId));
  }

  Future<void> _addToCart(Product product) async {
    final variant = product.variantById(_variantId);
    if (product.hasVariants && variant == null) {
      showErrorSnackBar(context, AppStrings.selectVariant);
      return;
    }
    final ok = await runAction('cart', () async {
      final uid = ref.read(authUserProvider).value?.uid;
      if (uid == null) throw const AppException(AppStrings.errNotSignedIn);
      await ref.read(cartRepositoryProvider).addItem(
            uid: uid,
            product: product,
            variant: variant,
            quantity: _quantity,
          );
    });
    if (ok && mounted) {
      setState(() => _added = true);
      showInfoSnackBar(context, AppStrings.addedToCart);
    }
  }

  void _goToCart() {
    ref.read(shellTabStateProvider.notifier).select(ShellTab.cart);
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return productAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: const [
            AspectRatio(aspectRatio: 1, child: ShimmerBox()),
            SizedBox(height: Gap.m),
            ShimmerBox(height: 24, width: 220),
            SizedBox(height: Gap.s),
            ShimmerBox(height: 32, width: 140),
          ],
        ),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.wifi_off_rounded,
          title: AppStrings.errGeneric,
          message: AppStrings.errNoInternet,
          actionLabel: AppStrings.retry,
          onAction: () => ref.invalidate(productByIdProvider(widget.productId)),
        ),
      ),
      data: (product) {
        if (product == null || !product.active) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: AppStrings.noProductsTitle,
              message: AppStrings.productNotFound,
            ),
          );
        }
        // Default to the first in-stock variant.
        if (product.hasVariants && product.variantById(_variantId) == null) {
          final firstAvailable = product.variants.firstWhere(
              (v) => v.stock > 0,
              orElse: () => product.variants.first);
          _variantId = firstAvailable.id;
        }
        return _buildLoaded(product);
      },
    );
  }

  Widget _buildLoaded(Product product) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final variant = product.variantById(_variantId);
    final stock = product.stockFor(variant);
    final related = ref.watch(relatedProductsProvider(product.id));
    final reviews = ref.watch(productReviewsProvider(product.id));
    if (_quantity > stock && stock > 0) _quantity = stock;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight:
                MediaQuery.sizeOf(context).width.clamp(0.0, 520.0).toDouble(),
            actions: [
              WishlistButton(productId: product.id),
              const SizedBox(width: Gap.s),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _Gallery(product: product),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(Gap.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.brand.isNotEmpty)
                        Text(product.brand,
                            style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600)),
                      const SizedBox(height: Gap.xs),
                      Text(product.name,
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: Gap.s),
                      if (product.ratingCount > 0)
                        Row(children: [
                          RatingStars(rating: product.ratingAvg, size: 18),
                          const SizedBox(width: Gap.s),
                          Text(
                            '${product.ratingAvg.toStringAsFixed(1)} · ${product.ratingCount} ${AppStrings.ratings}',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ]),
                      const SizedBox(height: Gap.m),
                      PriceTag(
                        price: product.priceFor(variant),
                        mrp: product.mrpFor(variant),
                        large: true,
                      ),
                      Text(AppStrings.inclusiveOfTaxes,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: Gap.m),
                      _StockLabel(stock: stock),
                      if (product.hasVariants) ...[
                        const SizedBox(height: Gap.l),
                        Text(
                          product.variantLabel.isEmpty
                              ? AppStrings.selectVariant
                              : product.variantLabel,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: Gap.s),
                        Wrap(
                          spacing: Gap.s,
                          runSpacing: Gap.s,
                          children: [
                            for (final v in product.variants)
                              ChoiceChip(
                                label: Text(v.label),
                                selected: v.id == _variantId,
                                onSelected: v.stock > 0
                                    ? (_) => setState(() {
                                          _variantId = v.id;
                                          _quantity = 1;
                                          _added = false;
                                        })
                                    : null,
                              ),
                          ],
                        ),
                      ],
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: Gap.l),
                        Text(AppStrings.description,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: Gap.s),
                        _ExpandableText(product.description),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _ReviewsSection(product: product, reviews: reviews)),
          SliverToBoxAdapter(
            child: related.maybeWhen(
              data: (list) => list.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(title: AppStrings.youMayAlsoLike),
                        ProductRail(products: list),
                      ],
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: Gap.xl)),
        ],
      ),
      bottomNavigationBar: Material(
        elevation: 8,
        color: scheme.surface,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Gap.m),
            child: Row(
              children: [
                if (stock > 0 && !_added) ...[
                  QuantityStepper(
                    value: _quantity,
                    max: stock,
                    onChanged: (v) => setState(() => _quantity = v),
                  ),
                  const SizedBox(width: Gap.m),
                ],
                Expanded(
                  child: _added
                      ? PrimaryButton(
                          label: AppStrings.goToCart,
                          icon: Icons.shopping_cart_rounded,
                          onPressed: _goToCart,
                        )
                      : PrimaryButton(
                          label: stock > 0
                              ? AppStrings.addToCart
                              : AppStrings.outOfStock,
                          loading: isBusy('cart'),
                          onPressed: stock > 0 && !isAnyBusy
                              ? () => _addToCart(product)
                              : null,
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

class _Gallery extends StatefulWidget {
  const _Gallery({required this.product});

  final Product product;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images;
    final heroTag = productHeroTag(widget.product.id);
    if (images.isEmpty) {
      return Hero(tag: heroTag, child: const AppNetworkImage(url: null));
    }
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) {
            final img = GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => ImageViewerScreen(
                  images: images,
                  initialIndex: i,
                  heroTag: i == 0 ? heroTag : null,
                ),
              )),
              child: AppNetworkImage(url: images[i]),
            );
            return i == 0 ? Hero(tag: heroTag, child: img) : img;
          },
        ),
        if (images.length > 1)
          Positioned(
            bottom: Gap.m,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? scheme.primary
                        : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _StockLabel extends StatelessWidget {
  const _StockLabel({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final (text, color, icon) = stock <= 0
        ? (AppStrings.outOfStock, AppColors.danger, Icons.cancel_outlined)
        : stock <= AppConstants.lowStockThreshold
            ? (fill(AppStrings.onlyFewLeft, {'n': stock}), AppColors.warning,
                Icons.error_outline_rounded)
            : (AppStrings.inStock, AppColors.success,
                Icons.check_circle_outline_rounded);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: Gap.xs + 2),
        Text(text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final long = widget.text.length > 220;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            maxLines: _expanded || !long ? null : 4,
            overflow: _expanded || !long ? null : TextOverflow.ellipsis,
            style: const TextStyle(height: 1.5),
          ),
        ),
        if (long)
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? AppStrings.showLess : AppStrings.showMore),
          ),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.product, required this.reviews});

  final Product product;
  final AsyncValue<List<Review>> reviews;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateFmt = DateFormat('d MMM yyyy');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: AppStrings.ratingsAndReviews),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.m),
              child: reviews.when(
                loading: () => const ShimmerBox(height: 80),
                error: (_, _) => Text(AppStrings.errGeneric,
                    style: TextStyle(color: muted)),
                data: (list) {
                  if (list.isEmpty) {
                    return Text(AppStrings.noReviewsYet,
                        style: TextStyle(color: muted));
                  }
                  return Column(
                    children: [
                      for (final r in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Gap.m),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(Gap.m),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      RatingStars(rating: r.rating.toDouble()),
                                      const SizedBox(width: Gap.s),
                                      Expanded(
                                        child: Text(r.userName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                      ),
                                      if (r.createdAt != null)
                                        Text(dateFmt.format(r.createdAt!),
                                            style: TextStyle(
                                                color: muted, fontSize: 12)),
                                    ],
                                  ),
                                  if (r.comment.isNotEmpty) ...[
                                    const SizedBox(height: Gap.s),
                                    Text(r.comment),
                                  ],
                                  if (r.imageUrls.isNotEmpty) ...[
                                    const SizedBox(height: Gap.s),
                                    SizedBox(
                                      height: 64,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: r.imageUrls.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(width: Gap.s),
                                        itemBuilder: (context, i) => InkWell(
                                          onTap: () => Navigator.of(context)
                                              .push(MaterialPageRoute(
                                            fullscreenDialog: true,
                                            builder: (_) => ImageViewerScreen(
                                                images: r.imageUrls,
                                                initialIndex: i),
                                          )),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: AppNetworkImage(
                                                url: r.imageUrls[i],
                                                width: 64,
                                                height: 64),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
