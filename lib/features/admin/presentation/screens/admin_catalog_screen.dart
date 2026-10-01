import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../catalog/data/models/product_category.dart';
import '../../../catalog/data/models/promo_banner.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/image_upload_field.dart';
import 'admin_product_form.dart' show Validators2;

/// Categories and banners share one screen with two tabs.
class AdminCatalogScreen extends ConsumerWidget {
  const AdminCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: AppStrings.categories2),
            Tab(text: AppStrings.banners),
          ]),
          const Expanded(
            child: TabBarView(children: [_CategoriesTab(), _BannersTab()]),
          ),
        ],
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    Future<void> open([ProductCategory? c]) => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: true,
          builder: (_) => _CategorySheet(category: c),
        );

    Future<void> remove(ProductCategory c) async {
      final yes = await confirmDialog(context,
          title: AppStrings.confirmDelete, confirmLabel: AppStrings.delete, destructive: true);
      if (!yes) return;
      try {
        await ref.read(adminRepositoryProvider).deleteCategory(c.id);
      } catch (e) {
        final msg = ErrorMapper.message(e);
        if (context.mounted && msg != null) showErrorSnackBar(context, msg);
      }
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'cat',
        onPressed: open,
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.newCategory),
      ),
      body: AdminPage(
        child: AdminAsyncList<ProductCategory>(
          value: categories,
          emptyIcon: Icons.category_outlined,
          emptyMessage: AppStrings.noCategoriesAdmin,
          onRetry: () => ref.invalidate(categoriesProvider),
          builder: (list) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 96),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: Gap.s),
            itemBuilder: (context, i) {
              final c = list[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minTileHeight: 64,
                  onTap: () => open(c),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppNetworkImage(url: c.imageUrl, width: 44, height: 44),
                  ),
                  title: Text(c.name),
                  subtitle: Text('${AppStrings.sortOrder}: ${c.sortOrder}'),
                  trailing: IconButton(
                    tooltip: AppStrings.delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => remove(c),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CategorySheet extends ConsumerStatefulWidget {
  const _CategorySheet({this.category});

  final ProductCategory? category;

  @override
  ConsumerState<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends ConsumerState<_CategorySheet>
    with AsyncActionMixin<_CategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name);
  late final _sort = TextEditingController(text: '${widget.category?.sortOrder ?? 0}');
  late List<String> _images = [if (widget.category?.imageUrl.isNotEmpty ?? false) widget.category!.imageUrl];
  late bool _active = widget.category?.active ?? true;

  @override
  void dispose() {
    _name.dispose();
    _sort.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await runAction(
      'save',
      () => ref.read(adminRepositoryProvider).saveCategory(ProductCategory(
            id: widget.category?.id ?? '',
            name: _name.text.trim(),
            imageUrl: _images.isEmpty ? '' : _images.first,
            sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
            active: _active,
          )),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Gap.l, 0, Gap.l, MediaQuery.of(context).viewInsets.bottom + Gap.l),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.category == null ? AppStrings.newCategory : AppStrings.editCategory,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.l),
            AppTextField(
              controller: _name,
              label: AppStrings.categoryName,
              textCapitalization: TextCapitalization.words,
              validator: Validators2.required,
            ),
            const SizedBox(height: Gap.m),
            NumberField(controller: _sort, label: AppStrings.sortOrder, allowDecimal: false),
            const SizedBox(height: Gap.l),
            ImageUploadField(
              urls: _images,
              folder: 'catalog/categories',
              max: 1,
              label: AppStrings.image,
              onChanged: (u) => setState(() => _images = u),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.active),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: Gap.m),
            PrimaryButton(label: AppStrings.save, loading: isBusy('save'), onPressed: isAnyBusy ? null : _save),
          ]),
        ),
      ),
    );
  }
}

class _BannersTab extends ConsumerWidget {
  const _BannersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(bannersProvider);

    Future<void> open([PromoBanner? b]) => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: true,
          builder: (_) => _BannerSheet(banner: b),
        );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'banner',
        onPressed: open,
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.newBanner),
      ),
      body: AdminPage(
        child: banners.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const EmptyState(
            icon: Icons.wifi_off_rounded,
            title: AppStrings.errGeneric,
            message: AppStrings.errNoInternet,
          ),
          data: (list) => list.isEmpty
              ? const EmptyState(
                  icon: Icons.photo_library_outlined,
                  title: AppStrings.noResults,
                  message: AppStrings.noBanners,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Gap.s),
                  itemBuilder: (context, i) {
                    final b = list[i];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        minTileHeight: 64,
                        onTap: () => open(b),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppNetworkImage(url: b.imageUrl, width: 64, height: 44),
                        ),
                        title: Text(b.title.isEmpty ? AppStrings.banners : b.title),
                        subtitle: Text(b.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          tooltip: AppStrings.delete,
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            final yes = await confirmDialog(context,
                                title: AppStrings.confirmDelete,
                                confirmLabel: AppStrings.delete,
                                destructive: true);
                            if (yes) {
                              await ref.read(adminRepositoryProvider).deleteBanner(b.id);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _BannerSheet extends ConsumerStatefulWidget {
  const _BannerSheet({this.banner});

  final PromoBanner? banner;

  @override
  ConsumerState<_BannerSheet> createState() => _BannerSheetState();
}

class _BannerSheetState extends ConsumerState<_BannerSheet>
    with AsyncActionMixin<_BannerSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.banner?.title);
  late final _subtitle = TextEditingController(text: widget.banner?.subtitle);
  late final _sort = TextEditingController(text: '${widget.banner?.sortOrder ?? 0}');
  late final _productId = TextEditingController(text: widget.banner?.targetProductId);
  late List<String> _images = [if (widget.banner?.imageUrl.isNotEmpty ?? false) widget.banner!.imageUrl];
  late String? _categoryId = widget.banner?.targetCategoryId;
  late String _target = widget.banner?.targetProductId != null
      ? 'product'
      : widget.banner?.targetCategoryId != null
          ? 'category'
          : 'none';
  late bool _active = widget.banner?.active ?? true;

  @override
  void dispose() {
    for (final c in [_title, _subtitle, _sort, _productId]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      showErrorSnackBar(context, AppStrings.errImageRequired);
      return;
    }
    final ok = await runAction(
      'save',
      () => ref.read(adminRepositoryProvider).saveBanner(PromoBanner(
            id: widget.banner?.id ?? '',
            imageUrl: _images.first,
            title: _title.text.trim(),
            subtitle: _subtitle.text.trim(),
            targetCategoryId: _target == 'category' ? _categoryId : null,
            targetProductId: _target == 'product' ? _productId.text.trim() : null,
            sortOrder: int.tryParse(_sort.text.trim()) ?? 0,
            active: _active,
          )),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? const [];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Gap.l, 0, Gap.l, MediaQuery.of(context).viewInsets.bottom + Gap.l),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.banner == null ? AppStrings.newBanner : AppStrings.editBanner,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.l),
            ImageUploadField(
              urls: _images,
              folder: 'catalog/banners',
              max: 1,
              label: AppStrings.image,
              onChanged: (u) => setState(() => _images = u),
            ),
            const SizedBox(height: Gap.m),
            AppTextField(controller: _title, label: AppStrings.bannerTitle),
            const SizedBox(height: Gap.m),
            AppTextField(controller: _subtitle, label: AppStrings.bannerSubtitle),
            const SizedBox(height: Gap.m),
            NumberField(controller: _sort, label: AppStrings.sortOrder, allowDecimal: false),
            const SizedBox(height: Gap.l),
            Text(AppStrings.bannerTarget, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: Gap.s),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'none', label: Text(AppStrings.targetNone)),
                ButtonSegment(value: 'category', label: Text(AppStrings.targetCategory)),
                ButtonSegment(value: 'product', label: Text(AppStrings.targetProduct)),
              ],
              selected: {_target},
              onSelectionChanged: (s) => setState(() => _target = s.first),
            ),
            if (_target == 'category') ...[
              const SizedBox(height: Gap.m),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: AppStrings.productCategory),
                items: [for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name))],
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? AppStrings.errCategoryRequired : null,
              ),
            ],
            if (_target == 'product') ...[
              const SizedBox(height: Gap.m),
              AppTextField(
                controller: _productId,
                label: AppStrings.productId,
                validator: Validators2.required,
              ),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.active),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: Gap.m),
            PrimaryButton(label: AppStrings.save, loading: isBusy('save'), onPressed: isAnyBusy ? null : _save),
          ]),
        ),
      ),
    );
  }
}
