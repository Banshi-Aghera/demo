import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../domain/product_filter.dart';
import '../providers/catalog_providers.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  ProductFilter _filter = const ProductFilter(sort: ProductSort.popular);

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () {
      if (mounted) setState(() => _query = v.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final results =
        _query.isEmpty ? null : ref.watch(searchResultsProvider(_query));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
          onSubmitted: (v) => setState(() => _query = v.trim()),
          decoration: InputDecoration(
            hintText: AppStrings.searchHint,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  ),
          ),
        ),
        actions: [
          if (results?.value?.isNotEmpty ?? false) ...[
            PopupMenuButton<ProductSort>(
              tooltip: AppStrings.sortBy,
              icon: const Icon(Icons.sort_rounded),
              initialValue: _filter.sort,
              onSelected: (s) =>
                  setState(() => _filter = _filter.copyWith(sort: s)),
              itemBuilder: (_) => [
                for (final s in ProductSort.values)
                  PopupMenuItem(value: s, child: Text(s.label)),
              ],
            ),
            IconButton(
              tooltip: AppStrings.filters,
              icon: Badge(
                isLabelVisible: _filter.activeCount > 0,
                label: Text('${_filter.activeCount}'),
                child: const Icon(Icons.tune_rounded),
              ),
              onPressed: () async {
                final f = await showFilterSheet(context,
                    current: _filter, products: results!.value!);
                if (f != null) setState(() => _filter = f);
              },
            ),
          ],
        ],
      ),
      body: results == null
          ? const EmptyState(
              icon: Icons.search_rounded,
              title: AppStrings.searchEmptyTitle,
              message: AppStrings.searchEmptyBody,
            )
          : results.when(
              loading: () => const CustomScrollView(
                  slivers: [ProductGridSkeleton(count: 4)]),
              error: (_, _) => EmptyState(
                icon: Icons.wifi_off_rounded,
                title: AppStrings.errGeneric,
                message: AppStrings.errNoInternet,
                actionLabel: AppStrings.retry,
                onAction: () => ref.invalidate(searchResultsProvider(_query)),
              ),
              data: (raw) {
                final list = _filter.apply(raw);
                if (list.isEmpty) {
                  return EmptyState(
                    icon: Icons.search_off_rounded,
                    title: AppStrings.searchNoResultsTitle,
                    message: raw.isNotEmpty
                        ? AppStrings.noProductsMatchFilters
                        : AppStrings.searchNoResultsBody,
                    actionLabel:
                        raw.isNotEmpty ? AppStrings.clearFilters : null,
                    onAction: raw.isNotEmpty
                        ? () => setState(() => _filter = _filter.cleared())
                        : null,
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(Gap.m),
                  gridDelegate: productGridDelegate,
                  itemCount: list.length,
                  itemBuilder: (context, i) => ProductCard(product: list[i]),
                );
              },
            ),
    );
  }
}
