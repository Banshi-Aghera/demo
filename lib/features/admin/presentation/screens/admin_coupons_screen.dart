import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../cart/data/models/coupon.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminCouponsScreen extends ConsumerWidget {
  const AdminCouponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coupons = ref.watch(adminCouponsProvider);
    final dateFmt = DateFormat('d MMM yyyy');

    Future<void> open([Coupon? c]) => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: true,
          builder: (_) => _CouponSheet(coupon: c),
        );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: open,
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.newCoupon),
      ),
      body: AdminPage(
        child: AdminAsyncList<Coupon>(
          value: coupons,
          emptyIcon: Icons.local_offer_outlined,
          emptyMessage: AppStrings.noCoupons,
          onRetry: () => ref.invalidate(adminCouponsProvider),
          builder: (list) {
            final sorted = [...list]..sort((a, b) => a.code.compareTo(b.code));
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 96),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: Gap.s),
              itemBuilder: (context, i) {
                final c = sorted[i];
                final expired = c.expiresAt != null && DateTime.now().isAfter(c.expiresAt!);
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    minTileHeight: 72,
                    onTap: () => open(c),
                    leading: Icon(Icons.local_offer_rounded,
                        color: !c.active || expired ? AppColors.danger : AppColors.success),
                    title: Row(children: [
                      Text(c.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: Gap.s),
                      Text(c.summary, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ]),
                    subtitle: Text([
                      if (c.minOrder > 0) 'Min ${Money.format(c.minOrder)}',
                      if (c.expiresAt != null) '${AppStrings.expiresOn} ${dateFmt.format(c.expiresAt!)}',
                      '${AppStrings.usedLabel}: ${c.usedCount}${c.usageLimit > 0 ? '/${c.usageLimit}' : ''}',
                      if (!c.active) AppStrings.inactive,
                      if (expired) AppStrings.errCouponExpired,
                    ].join(' · ')),
                    trailing: IconButton(
                      tooltip: AppStrings.delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        final yes = await confirmDialog(context,
                            title: AppStrings.confirmDelete,
                            confirmLabel: AppStrings.delete,
                            destructive: true);
                        if (yes) await ref.read(adminRepositoryProvider).deleteCoupon(c.code);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _CouponSheet extends ConsumerStatefulWidget {
  const _CouponSheet({this.coupon});

  final Coupon? coupon;

  @override
  ConsumerState<_CouponSheet> createState() => _CouponSheetState();
}

class _CouponSheetState extends ConsumerState<_CouponSheet>
    with AsyncActionMixin<_CouponSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.coupon?.code);
  late final _value = TextEditingController(text: _n(widget.coupon?.value));
  late final _minOrder = TextEditingController(text: _n(widget.coupon?.minOrder ?? 0));
  late final _maxDiscount = TextEditingController(text: _n(widget.coupon?.maxDiscount));
  late final _limit = TextEditingController(text: '${widget.coupon?.usageLimit ?? 0}');
  late CouponType _type = widget.coupon?.type ?? CouponType.percent;
  late DateTime? _expiry = widget.coupon?.expiresAt;
  late bool _active = widget.coupon?.active ?? true;

  static String _n(double? v) =>
      v == null ? '' : (v % 1 == 0 ? v.toStringAsFixed(0) : v.toString());

  @override
  void dispose() {
    for (final c in [_code, _value, _minOrder, _maxDiscount, _limit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final maxDiscount = double.tryParse(_maxDiscount.text.trim());
    final ok = await runAction(
      'save',
      () => ref.read(adminRepositoryProvider).saveCoupon(
            Coupon(
              id: '',
              code: _code.text.trim().toUpperCase(),
              type: _type,
              value: double.parse(_value.text.trim()),
              minOrder: double.tryParse(_minOrder.text.trim()) ?? 0,
              maxDiscount: maxDiscount,
              expiresAt: _expiry,
              usageLimit: int.tryParse(_limit.text.trim()) ?? 0,
              usedCount: widget.coupon?.usedCount ?? 0,
              active: _active,
            ),
            previousCode: widget.coupon?.code,
          ),
    );
    if (ok && mounted) {
      showInfoSnackBar(context, AppStrings.couponSaved);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM yyyy');
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Gap.l, 0, Gap.l, MediaQuery.of(context).viewInsets.bottom + Gap.l),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.coupon == null ? AppStrings.newCoupon : AppStrings.editCoupon,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.l),
            AppTextField(
              controller: _code,
              label: AppStrings.couponCodeLabel,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => RegExp(r'^[A-Za-z0-9]{3,20}$').hasMatch((v ?? '').trim())
                  ? null
                  : AppStrings.errCouponCodeFormat,
            ),
            const SizedBox(height: Gap.m),
            SegmentedButton<CouponType>(
              segments: const [
                ButtonSegment(value: CouponType.percent, label: Text(AppStrings.typePercent)),
                ButtonSegment(value: CouponType.flat, label: Text(AppStrings.typeFlat)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: Gap.m),
            NumberField(
              controller: _value,
              label: AppStrings.discountValue,
              prefix: _type == CouponType.flat ? '₹ ' : null,
              suffix: _type == CouponType.percent ? '%' : null,
            ),
            const SizedBox(height: Gap.m),
            NumberField(controller: _minOrder, label: AppStrings.minOrderValue, prefix: '₹ '),
            if (_type == CouponType.percent) ...[
              const SizedBox(height: Gap.m),
              TextFormField(
                controller: _maxDiscount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: AppStrings.maxDiscountValue, prefixText: '₹ '),
              ),
            ],
            const SizedBox(height: Gap.m),
            NumberField(controller: _limit, label: AppStrings.usageLimitLabel, allowDecimal: false),
            const SizedBox(height: Gap.m),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: Text(_expiry == null ? AppStrings.noExpiry : dateFmt.format(_expiry!)),
              subtitle: const Text(AppStrings.expiresOn),
              trailing: _expiry == null
                  ? TextButton(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: now,
                          lastDate: now.add(const Duration(days: 365 * 3)),
                          initialDate: now.add(const Duration(days: 30)),
                        );
                        if (picked != null) setState(() => _expiry = picked);
                      },
                      child: const Text(AppStrings.pickDate),
                    )
                  : IconButton(
                      tooltip: AppStrings.remove,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _expiry = null),
                    ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.couponActive),
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
