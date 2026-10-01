import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_spacing.dart';

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.radius = Gap.radius,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? const Color(0xFF223034) : const Color(0xFFE6E9EC),
      highlightColor: dark ? const Color(0xFF2E3F44) : const Color(0xFFF5F7F8),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Placeholder grid shown while product lists load.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(Gap.m),
      sliver: SliverGrid(
        gridDelegate: productGridDelegate,
        delegate: SliverChildBuilderDelegate(
          (context, i) => const ShimmerBox(),
          childCount: count,
        ),
      ),
    );
  }
}

const productGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 220,
  mainAxisSpacing: Gap.m,
  crossAxisSpacing: Gap.m,
  childAspectRatio: 0.52,
);

/// Placeholder for horizontal product rails.
class ProductRailSkeleton extends StatelessWidget {
  const ProductRailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.m),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.m),
        itemBuilder: (_, _) => const ShimmerBox(width: 160),
      ),
    );
  }
}
