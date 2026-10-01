import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/snackbars.dart';
import '../providers/cart_providers.dart';

class CouponCard extends ConsumerStatefulWidget {
  const CouponCard({super.key, this.couponError});

  /// Shown when the applied coupon stopped qualifying.
  final String? couponError;

  @override
  ConsumerState<CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends ConsumerState<CouponCard>
    with AsyncActionMixin<CouponCard> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_code.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    final ok = await runAction('apply',
        () => ref.read(appliedCouponProvider.notifier).apply(_code.text));
    if (ok && mounted) {
      _code.clear();
      showInfoSnackBar(context, AppStrings.couponApplied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupon = ref.watch(appliedCouponProvider);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.m),
        child: coupon != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_offer_rounded,
                          color: widget.couponError == null
                              ? AppColors.success
                              : scheme.error),
                      const SizedBox(width: Gap.s),
                      Expanded(
                        child: Text(
                          '${coupon.code} · ${coupon.summary}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.read(appliedCouponProvider.notifier).remove(),
                        child: const Text(AppStrings.remove),
                      ),
                    ],
                  ),
                  if (widget.couponError != null)
                    Text(widget.couponError!,
                        style: TextStyle(color: scheme.error, fontSize: 13)),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _code,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _apply(),
                      decoration: const InputDecoration(
                        labelText: AppStrings.couponCode,
                        prefixIcon: Icon(Icons.local_offer_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.s),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(88, 56)),
                    onPressed: isAnyBusy ? null : _apply,
                    child: isBusy('apply')
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text(AppStrings.applyCoupon),
                  ),
                ],
              ),
      ),
    );
  }
}
