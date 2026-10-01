import 'package:flutter/material.dart';

import '../constants/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';

/// Selling price, struck-through MRP and the % off badge.
class PriceTag extends StatelessWidget {
  const PriceTag({
    super.key,
    required this.price,
    required this.mrp,
    this.large = false,
  });

  final double price;
  final double mrp;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final hasDiscount = mrp > price && mrp > 0;
    final percent = hasDiscount ? (((mrp - price) / mrp) * 100).round() : 0;

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Gap.s,
      runSpacing: 2,
      children: [
        Text(
          Money.format(price),
          style: (large
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.titleMedium)
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (hasDiscount) ...[
          Text(
            Money.format(mrp),
            style: (large ? theme.textTheme.bodyLarge : theme.textTheme.bodySmall)
                ?.copyWith(
              color: muted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '$percent% ${AppStrings.off}',
            style: (large ? theme.textTheme.bodyLarge : theme.textTheme.bodySmall)
                ?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Amber pill used for savings and "free delivery" highlights.
class SavingsBadge extends StatelessWidget {
  const SavingsBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
