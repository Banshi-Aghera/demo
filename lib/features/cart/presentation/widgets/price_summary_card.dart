import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/price_calculator.dart';

/// Price breakdown reused by the cart and (Phase 3) checkout.
class PriceSummaryCard extends StatelessWidget {
  const PriceSummaryCard({super.key, required this.summary});

  final CartSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget row(String label, String value,
        {Color? color, bool bold = false, double size = 14}) {
      final style = TextStyle(
        color: color,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.xs),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(value, style: style),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.priceDetails,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.s),
            row(AppStrings.itemTotalMrp, Money.format(summary.mrpTotal)),
            if (summary.productDiscount > 0)
              row(AppStrings.productDiscount,
                  '− ${Money.format(summary.productDiscount)}',
                  color: AppColors.success),
            if (summary.couponDiscount > 0)
              row(AppStrings.couponDiscount,
                  '− ${Money.format(summary.couponDiscount)}',
                  color: AppColors.success),
            row(
              AppStrings.deliveryFee,
              summary.deliveryFee == 0
                  ? AppStrings.free
                  : Money.format(summary.deliveryFee),
              color: summary.deliveryFee == 0 ? AppColors.success : null,
            ),
            row(AppStrings.gstIncluded, Money.format(summary.gstIncluded),
                color: muted, size: 13),
            const Divider(height: Gap.l),
            row(AppStrings.grandTotal, Money.format(summary.grandTotal),
                bold: true, size: 16),
            if (summary.totalSavings > 0) ...[
              const SizedBox(height: Gap.s),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Gap.s + 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${AppStrings.youSave} ${Money.format(summary.totalSavings)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
