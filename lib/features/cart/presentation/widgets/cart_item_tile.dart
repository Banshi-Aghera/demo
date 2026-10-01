import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/price_tag.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../data/models/cart_item.dart';
import '../providers/cart_providers.dart';

class CartItemTile extends ConsumerStatefulWidget {
  const CartItemTile({super.key, required this.item});

  final CartItem item;

  @override
  ConsumerState<CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends ConsumerState<CartItemTile> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && success != null) showInfoSnackBar(context, success);
    } catch (e) {
      final msg = ErrorMapper.message(e);
      if (mounted && msg != null) showErrorSnackBar(context, msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final actions = ref.read(cartActionsProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.s + 4),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push(Routes.productPath(item.productId)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppNetworkImage(
                        url: item.imageUrl, width: 84, height: 84),
                  ),
                  const SizedBox(width: Gap.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        if (item.variantLabel != null)
                          Text(item.variantLabel!,
                              style: TextStyle(color: muted, fontSize: 13)),
                        const SizedBox(height: Gap.xs),
                        PriceTag(price: item.unitPrice, mrp: item.mrp),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.s),
            Row(
              children: [
                QuantityStepper(
                  value: item.quantity,
                  min: 0,
                  max: item.maxStock > 0 ? item.maxStock : null,
                  busy: _busy,
                  onChanged: (v) => _run(() => actions.setQuantity(item, v)),
                ),
                const Spacer(),
                IconButton(
                  tooltip: AppStrings.moveToWishlist,
                  icon: const Icon(Icons.favorite_border_rounded),
                  onPressed: _busy
                      ? null
                      : () => _run(() => actions.moveToWishlist(item),
                          success: AppStrings.movedToWishlist),
                ),
                IconButton(
                  tooltip: AppStrings.remove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed:
                      _busy ? null : () => _run(() => actions.remove(item)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
