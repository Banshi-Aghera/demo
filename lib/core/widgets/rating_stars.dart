import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 14});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = rating - i;
        final icon = fill >= 0.75
            ? Icons.star_rounded
            : fill >= 0.25
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;
        return Icon(icon, size: size, color: AppColors.accent);
      }),
    );
  }
}

/// Compact "4.3 ★ (128)" chip for cards.
class RatingChip extends StatelessWidget {
  const RatingChip({super.key, required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(rating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(width: 2),
        const Icon(Icons.star_rounded, size: 14, color: AppColors.accent),
        const SizedBox(width: 4),
        Text('($count)', style: TextStyle(color: muted, fontSize: 12)),
      ],
    );
  }
}
