import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import '../../domain/product_filter.dart';

/// Opens the filter sheet; resolves to the new filter or null if dismissed.
Future<ProductFilter?> showFilterSheet(
  BuildContext context, {
  required ProductFilter current,
  required List<Product> products,
}) {
  return showModalBottomSheet<ProductFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _FilterSheet(current: current, products: products),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.products});

  final ProductFilter current;
  final List<Product> products;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final double _floor;
  late final double _ceiling;
  late RangeValues _range;
  late Set<String> _brands;
  late double _minRating;
  late final List<String> _allBrands;

  @override
  void initState() {
    super.initState();
    final prices = widget.products.map((p) => p.displayPrice).toList();
    _floor = prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b).floorToDouble();
    _ceiling = prices.isEmpty ? 1000 : prices.reduce((a, b) => a > b ? a : b).ceilToDouble();
    final ceiling = _ceiling <= _floor ? _floor + 1 : _ceiling;
    _range = RangeValues(
      (widget.current.minPrice ?? _floor).clamp(_floor, ceiling),
      (widget.current.maxPrice ?? ceiling).clamp(_floor, ceiling),
    );
    _brands = {...widget.current.brands};
    _minRating = widget.current.minRating;
    _allBrands = widget.products
        .map((p) => p.brand)
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  double get _safeCeiling => _ceiling <= _floor ? _floor + 1 : _ceiling;

  void _apply() {
    final priceUntouched = _range.start <= _floor && _range.end >= _safeCeiling;
    Navigator.pop(
      context,
      ProductFilter(
        minPrice: priceUntouched ? null : _range.start,
        maxPrice: priceUntouched ? null : _range.end,
        brands: _brands,
        minRating: _minRating,
        sort: widget.current.sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600);

    return Padding(
      padding: EdgeInsets.only(
        left: Gap.l,
        right: Gap.l,
        bottom: MediaQuery.of(context).viewInsets.bottom + Gap.l,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.filters,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.l),
            Text(AppStrings.priceRange, style: titleStyle),
            RangeSlider(
              min: _floor,
              max: _safeCeiling,
              values: _range,
              labels: RangeLabels(
                  Money.format(_range.start), Money.format(_range.end)),
              onChanged: (v) => setState(() => _range = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Money.format(_range.start)),
                Text(Money.format(_range.end)),
              ],
            ),
            if (_allBrands.isNotEmpty) ...[
              const SizedBox(height: Gap.l),
              Text(AppStrings.brand, style: titleStyle),
              const SizedBox(height: Gap.s),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  for (final b in _allBrands)
                    FilterChip(
                      label: Text(b),
                      selected: _brands.contains(b),
                      onSelected: (on) => setState(
                          () => on ? _brands.add(b) : _brands.remove(b)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: Gap.l),
            Text(AppStrings.customerRating, style: titleStyle),
            const SizedBox(height: Gap.s),
            Wrap(
              spacing: Gap.s,
              children: [
                for (final r in [0.0, 3.0, 4.0])
                  ChoiceChip(
                    label: Text(r == 0
                        ? AppStrings.anyRating
                        : '${r.toStringAsFixed(0)}★ ${AppStrings.andUp}'),
                    selected: _minRating == r,
                    onSelected: (_) => setState(() => _minRating = r),
                  ),
              ],
            ),
            const SizedBox(height: Gap.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _range = RangeValues(_floor, _safeCeiling);
                      _brands = {};
                      _minRating = 0;
                    }),
                    child: const Text(AppStrings.reset),
                  ),
                ),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text(AppStrings.apply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
