import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../catalog/data/models/product.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/image_upload_field.dart';

class AdminProductForm extends ConsumerStatefulWidget {
  const AdminProductForm({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<AdminProductForm> createState() => _AdminProductFormState();
}

class _VariantRow {
  _VariantRow({String? id, String label = '', String price = '', String mrp = '', String stock = ''})
      : id = id ?? '',
        label = TextEditingController(text: label),
        price = TextEditingController(text: price),
        mrp = TextEditingController(text: mrp),
        stock = TextEditingController(text: stock);

  String id;
  final TextEditingController label;
  final TextEditingController price;
  final TextEditingController mrp;
  final TextEditingController stock;

  void dispose() {
    label.dispose();
    price.dispose();
    mrp.dispose();
    stock.dispose();
  }
}

class _AdminProductFormState extends ConsumerState<AdminProductForm>
    with AsyncActionMixin<AdminProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _brand = TextEditingController(text: widget.product?.brand);
  late final _description = TextEditingController(text: widget.product?.description);
  late final _price = TextEditingController(text: _num(widget.product?.price));
  late final _mrp = TextEditingController(text: _num(widget.product?.mrp));
  late final _stock = TextEditingController(text: widget.product?.stock.toString() ?? '0');
  late final _gst = TextEditingController(text: _num(widget.product?.gstRate ?? 18));
  late final _variantLabel = TextEditingController(text: widget.product?.variantLabel);

  late String? _categoryId = widget.product?.categoryId;
  late List<String> _images = [...?widget.product?.images];
  late bool _active = widget.product?.active ?? true;
  late bool _deal = widget.product?.isDealOfDay ?? false;
  late final List<_VariantRow> _variants = [
    for (final v in widget.product?.variants ?? const <ProductVariant>[])
      _VariantRow(
        id: v.id,
        label: v.label,
        price: _num(v.price),
        mrp: _num(v.mrp),
        stock: v.stock.toString(),
      ),
  ];

  static String _num(double? v) =>
      v == null ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString());

  bool get _editing => widget.product != null;

  @override
  void dispose() {
    for (final c in [_name, _brand, _description, _price, _mrp, _stock, _gst, _variantLabel]) {
      c.dispose();
    }
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      showErrorSnackBar(context, AppStrings.errCategoryRequired);
      return;
    }
    if (_images.isEmpty) {
      showErrorSnackBar(context, AppStrings.errImageRequired);
      return;
    }

    final variants = <ProductVariant>[
      for (final v in _variants)
        if (v.label.text.trim().isNotEmpty)
          ProductVariant(
            // Keep the id stable so carts and orders still match.
            id: v.id.isEmpty
                ? v.label.text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-')
                : v.id,
            label: v.label.text.trim(),
            price: double.parse(v.price.text.trim()),
            mrp: double.parse(v.mrp.text.trim()),
            stock: int.parse(v.stock.text.trim()),
          ),
    ];

    final product = Product(
      id: widget.product?.id ?? '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      brand: _brand.text.trim(),
      categoryId: _categoryId!,
      images: _images,
      price: double.parse(_price.text.trim()),
      mrp: double.parse(_mrp.text.trim()),
      stock: int.parse(_stock.text.trim()),
      gstRate: double.parse(_gst.text.trim()),
      variantLabel: _variantLabel.text.trim(),
      variants: variants,
      ratingAvg: widget.product?.ratingAvg ?? 0,
      ratingCount: widget.product?.ratingCount ?? 0,
      soldCount: widget.product?.soldCount ?? 0,
      isDealOfDay: _deal,
      active: _active,
      createdAt: widget.product?.createdAt,
    );

    final ok = await runAction(
        'save', () => ref.read(adminRepositoryProvider).saveProduct(product));
    if (ok && mounted) {
      showInfoSnackBar(context, AppStrings.productSaved);
      Navigator.of(context).pop();
    }
  }

  String? _priceValidator(String? v) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null || n < 0) return AppStrings.errNumber;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final hasVariants = _variants.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? AppStrings.editProduct : AppStrings.newProduct),
      ),
      body: AdminPage(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(Gap.m),
            children: [
              AppTextField(
                controller: _name,
                label: AppStrings.productName,
                textCapitalization: TextCapitalization.words,
                validator: Validators2.required,
              ),
              const SizedBox(height: Gap.m),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: AppTextField(
                    controller: _brand,
                    label: AppStrings.productBrand,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: AppStrings.productCategory),
                    items: [
                      for (final c in categories)
                        DropdownMenuItem(value: c.id, child: Text(c.name)),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v),
                    validator: (v) => v == null ? AppStrings.errCategoryRequired : null,
                  ),
                ),
              ]),
              const SizedBox(height: Gap.m),
              TextFormField(
                controller: _description,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: AppStrings.productDescription, alignLabelWithHint: true),
              ),
              const SizedBox(height: Gap.l),
              ImageUploadField(
                urls: _images,
                folder: 'catalog/products',
                max: AppConstants.maxProductImages,
                onChanged: (urls) => setState(() => _images = urls),
              ),
              const SizedBox(height: Gap.l),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: NumberField(
                    controller: _price,
                    label: AppStrings.sellingPrice,
                    prefix: '₹ ',
                    validator: (v) {
                      final base = _priceValidator(v);
                      if (base != null) return base;
                      final price = double.parse(v!.trim());
                      final mrp = double.tryParse(_mrp.text.trim());
                      if (mrp != null && price > mrp) return AppStrings.errPriceAboveMrp;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: NumberField(
                      controller: _mrp, label: AppStrings.mrpLabel, prefix: '₹ ',
                      validator: _priceValidator),
                ),
              ]),
              const SizedBox(height: Gap.m),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: NumberField(
                    controller: _stock,
                    label: AppStrings.stockLabel,
                    allowDecimal: false,
                    validator: (v) {
                      if (hasVariants) return null; // variant stock is used
                      return int.tryParse((v ?? '').trim()) == null
                          ? AppStrings.errNumber
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: NumberField(controller: _gst, label: AppStrings.gstRate, suffix: '%'),
                ),
              ]),
              const SizedBox(height: Gap.l),

              // Variants
              Row(children: [
                Expanded(
                  child: Text(AppStrings.variantsLabel,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _variants.add(_VariantRow())),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(AppStrings.addVariant),
                ),
              ]),
              if (hasVariants) ...[
                AppTextField(
                  controller: _variantLabel,
                  label: AppStrings.variantGroupLabel,
                  validator: Validators2.required,
                ),
                const SizedBox(height: Gap.s),
                for (final v in _variants)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Gap.s),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(Gap.s + 4),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: v.label,
                              decoration: const InputDecoration(labelText: AppStrings.variantName),
                              validator: Validators2.required,
                            ),
                          ),
                          const SizedBox(width: Gap.s),
                          Expanded(
                            flex: 2,
                            child: NumberField(
                                controller: v.price, label: AppStrings.sellingPrice, prefix: '₹'),
                          ),
                          const SizedBox(width: Gap.s),
                          Expanded(
                            flex: 2,
                            child: NumberField(
                                controller: v.mrp, label: AppStrings.mrpLabel, prefix: '₹'),
                          ),
                          const SizedBox(width: Gap.s),
                          Expanded(
                            flex: 2,
                            child: NumberField(
                                controller: v.stock,
                                label: AppStrings.stockLabel,
                                allowDecimal: false),
                          ),
                          IconButton(
                            tooltip: AppStrings.remove,
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() {
                              _variants.remove(v);
                              v.dispose();
                            }),
                          ),
                        ]),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: Gap.m),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.productActive),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.markDealOfDay),
                value: _deal,
                onChanged: (v) => setState(() => _deal = v),
              ),
              const SizedBox(height: Gap.l),
              PrimaryButton(
                label: AppStrings.save,
                loading: isBusy('save'),
                onPressed: isAnyBusy ? null : _save,
              ),
              const SizedBox(height: Gap.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small helper so admin forms don't import the customer validators file.
class Validators2 {
  Validators2._();
  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? AppStrings.required_ : null;
}
