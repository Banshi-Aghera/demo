import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../catalog/data/models/product.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_product_form.dart';

enum _StockFilter { all, inStock, low, out }

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  String _query = '';
  String? _categoryId;
  _StockFilter _stock = _StockFilter.all;

  List<Product> _apply(List<Product> all) {
    final q = _query.toLowerCase();
    return all.where((p) {
      if (q.isNotEmpty &&
          !'${p.name} ${p.brand}'.toLowerCase().contains(q)) return false;
      if (_categoryId != null && p.categoryId != _categoryId) return false;
      final stock = p.stockFor(null);
      return switch (_stock) {
        _StockFilter.all => true,
        _StockFilter.inStock => stock > 0,
        _StockFilter.low => stock > 0 && stock <= AppConstants.lowStockThreshold,
        _StockFilter.out => stock <= 0,
      };
    }).toList();
  }

  Future<void> _openForm([Product? product]) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AdminProductForm(product: product)),
      );

  Future<void> _delete(Product p) async {
    final yes = await confirmDialog(context,
        title: AppStrings.deleteProduct,
        body: AppStrings.deleteProductBody,
        confirmLabel: AppStrings.delete,
        destructive: true);
    if (!yes) return;
    try {
      await ref.read(adminRepositoryProvider).deleteProduct(p.id);
      if (mounted) showInfoSnackBar(context, AppStrings.deleted);
    } catch (e) {
      final msg = ErrorMapper.message(e);
      if (mounted && msg != null) showErrorSnackBar(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(adminProductsProvider);
    final categories = ref.watch(categoriesProvider).value ?? const [];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.newProduct),
      ),
      body: AdminPage(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: Column(children: [
                AdminSearchField(
                  hint: AppStrings.searchProducts,
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: Gap.s),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    DropdownMenu<String?>(
                      initialSelection: _categoryId,
                      label: const Text(AppStrings.filterCategory),
                      onSelected: (v) => setState(() => _categoryId = v),
                      dropdownMenuEntries: [
                        const DropdownMenuEntry(value: null, label: AppStrings.all),
                        for (final c in categories)
                          DropdownMenuEntry(value: c.id, label: c.name),
                      ],
                    ),
                    const SizedBox(width: Gap.m),
                    SegmentedButton<_StockFilter>(
                      style: const ButtonStyle(visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(value: _StockFilter.all, label: Text(AppStrings.all)),
                        ButtonSegment(value: _StockFilter.inStock, label: Text(AppStrings.inStockOnly)),
                        ButtonSegment(value: _StockFilter.low, label: Text(AppStrings.lowStockOnly)),
                        ButtonSegment(value: _StockFilter.out, label: Text(AppStrings.outOfStockOnly)),
                      ],
                      selected: {_stock},
                      onSelectionChanged: (s) => setState(() => _stock = s.first),
                    ),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: AdminAsyncList<Product>(
                value: products,
                emptyIcon: Icons.inventory_2_outlined,
                emptyMessage: AppStrings.noProductsAdmin,
                onRetry: () => ref.invalidate(adminProductsProvider),
                builder: (all) {
                  final list = _apply(all);
                  if (list.isEmpty) {
                    return const Center(child: Text(AppStrings.noResults));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, 96),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Gap.s),
                    itemBuilder: (context, i) {
                      final p = list[i];
                      final stock = p.stockFor(null);
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openForm(p),
                          child: Padding(
                            padding: const EdgeInsets.all(Gap.s + 4),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: AppNetworkImage(url: p.thumbnail, width: 56, height: 56),
                              ),
                              const SizedBox(width: Gap.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(
                                      '${Money.format(p.displayPrice)}'
                                      '${p.hasVariants ? ' · ${p.variants.length} ${AppStrings.variantsLabel.toLowerCase()}' : ''}',
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('$stock',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: stock == 0
                                            ? AppColors.danger
                                            : stock <= AppConstants.lowStockThreshold
                                                ? AppColors.warning
                                                : null,
                                      )),
                                  Text(AppStrings.stockLabel,
                                      style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                              if (!p.active)
                                const Padding(
                                  padding: EdgeInsets.only(left: Gap.s),
                                  child: Icon(Icons.visibility_off_outlined, size: 18),
                                ),
                              IconButton(
                                tooltip: AppStrings.delete,
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => _delete(p),
                              ),
                            ]),
                          ),
                        ),
                      );
                    },
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
