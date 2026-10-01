import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../wishlist/presentation/providers/wishlist_providers.dart';

class WishlistButton extends ConsumerStatefulWidget {
  const WishlistButton({super.key, required this.productId, this.filled = true});

  final String productId;

  /// Draws a circular surface behind the icon (for use over images).
  final bool filled;

  @override
  ConsumerState<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends ConsumerState<WishlistButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      final added = await toggleWishlist(ref, widget.productId);
      if (mounted) {
        showInfoSnackBar(context,
            added ? AppStrings.addedToWishlist : AppStrings.removedFromWishlist);
      }
    } catch (e) {
      final msg = ErrorMapper.message(e);
      if (mounted && msg != null) showErrorSnackBar(context, msg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(isWishlistedProvider(widget.productId));
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: AppStrings.wishlist,
      style: widget.filled
          ? IconButton.styleFrom(
              backgroundColor: scheme.surface.withValues(alpha: 0.9))
          : null,
      onPressed: _busy ? null : _toggle,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Icon(
          saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          key: ValueKey(saved),
          color: saved ? AppColors.danger : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
