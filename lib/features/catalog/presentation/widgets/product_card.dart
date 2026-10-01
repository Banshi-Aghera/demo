import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/price_tag.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../data/models/product.dart';
import 'wishlist_button.dart';

String productHeroTag(String productId) => 'product-image-$productId';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.width});

  final Product product;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final discount = product.displayDiscountPercent;

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(Routes.productPath(product.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: productHeroTag(product.id),
                      child: AppNetworkImage(url: product.thumbnail),
                    ),
                    if (!product.inStock)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: const Text(
                          AppStrings.outOfStock,
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (discount > 0)
                      Positioned(
                        left: Gap.s,
                        top: Gap.s,
                        child: SavingsBadge(label: '$discount% ${AppStrings.off}'),
                      ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: WishlistButton(productId: product.id),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.s + 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.brand.isNotEmpty)
                        Text(
                          product.brand,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      RatingChip(
                          rating: product.ratingAvg, count: product.ratingCount),
                      const SizedBox(height: 2),
                      PriceTag(
                          price: product.displayPrice, mrp: product.displayMrp),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal list of product cards used on Home and the product page.
class ProductRail extends StatelessWidget {
  const ProductRail({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.m),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.m),
        itemBuilder: (context, i) =>
            ProductCard(product: products[i], width: 168),
      ),
    );
  }
}
