import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/providers/services_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/app_order.dart';
import '../providers/orders_providers.dart';
import 'photo_picker_row.dart';

Future<void> showReviewSheet(BuildContext context, AppOrder order, OrderLine line) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _ReviewSheet(order: order, line: line),
  );
}

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.order, required this.line});

  final AppOrder order;
  final OrderLine line;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet>
    with AsyncActionMixin<_ReviewSheet> {
  int _rating = 0;
  final _comment = TextEditingController();
  final _photos = <XFile>[];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      showErrorSnackBar(context, AppStrings.errRatingRequired);
      return;
    }
    final ok = await runAction('submit', () async {
      final uid = ref.read(authUserProvider).value?.uid;
      if (uid == null) throw const AppException(AppStrings.errNotSignedIn);
      final storage = ref.read(storageServiceProvider);
      final urls = <String>[];
      for (final p in _photos) {
        urls.add(await storage.upload('reviews/$uid/${widget.line.productId}', p));
      }
      await ref.read(ordersRepositoryProvider).submitReview(
            orderId: widget.order.id,
            productId: widget.line.productId,
            rating: _rating,
            comment: _comment.text.trim(),
            imageUrls: urls,
          );
    });
    if (ok && mounted) {
      Navigator.pop(context);
      showInfoSnackBar(context, AppStrings.reviewThanks);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Gap.l, 0, Gap.l, MediaQuery.of(context).viewInsets.bottom + Gap.l),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppStrings.writeReview,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.xs),
            Text(widget.line.name, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: Gap.l),
            Text(AppStrings.yourRating, style: const TextStyle(fontWeight: FontWeight.w600)),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i',
                    iconSize: 36,
                    onPressed: () => setState(() => _rating = i),
                    icon: Icon(
                      i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Gap.m),
            TextField(
              controller: _comment,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: AppStrings.reviewCommentHint),
            ),
            const SizedBox(height: Gap.s),
            PhotoPickerRow(photos: _photos, max: AppConstants.maxReviewPhotos, onChanged: () => setState(() {})),
            const SizedBox(height: Gap.l),
            PrimaryButton(
              label: AppStrings.submitReview,
              loading: isBusy('submit'),
              onPressed: isAnyBusy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
