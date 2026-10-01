import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/providers/services_providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/option_tile.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/orders_providers.dart';
import '../widgets/photo_picker_row.dart';

const _reasons = <(String, String)>[
  ('damaged', AppStrings.reasonDamaged),
  ('wrongItem', AppStrings.reasonWrongItem),
  ('notAsDescribed', AppStrings.reasonNotAsDescribed),
  ('qualityIssue', AppStrings.reasonQuality),
  ('other', AppStrings.reasonOther),
];

class ReturnRequestScreen extends ConsumerStatefulWidget {
  const ReturnRequestScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<ReturnRequestScreen> createState() => _ReturnRequestScreenState();
}

class _ReturnRequestScreenState extends ConsumerState<ReturnRequestScreen>
    with AsyncActionMixin<ReturnRequestScreen> {
  String? _reason;
  final _comment = TextEditingController();
  final _photos = <XFile>[];

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      showErrorSnackBar(context, AppStrings.errReturnReason);
      return;
    }
    final ok = await runAction('submit', () async {
      final uid = ref.read(authUserProvider).value?.uid;
      if (uid == null) throw const AppException(AppStrings.errNotSignedIn);
      final storage = ref.read(storageServiceProvider);
      final urls = <String>[];
      for (final p in _photos) {
        urls.add(await storage.upload('returns/$uid/${widget.orderId}', p));
      }
      await ref.read(ordersRepositoryProvider).requestReturn(
            orderId: widget.orderId,
            reason: _reason!,
            comment: _comment.text.trim(),
            photoUrls: urls,
          );
    });
    if (ok && mounted) {
      showInfoSnackBar(context, AppStrings.returnSubmitted);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.returnTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(Gap.m),
            children: [
              Text(AppStrings.returnWindowNote, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: Gap.l),
              Text(AppStrings.returnReason,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: Gap.s),
              Card(
                child: Column(children: [
                  for (final (code, label) in _reasons)
                    OptionTile(
                      selected: _reason == code,
                      title: label,
                      onTap: () => setState(() => _reason = code),
                    ),
                ]),
              ),
              const SizedBox(height: Gap.l),
              TextField(
                controller: _comment,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: AppStrings.returnComment, alignLabelWithHint: true),
              ),
              const SizedBox(height: Gap.m),
              Text(AppStrings.addPhotos, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: Gap.s),
              PhotoPickerRow(photos: _photos, max: AppConstants.maxReturnPhotos, onChanged: () => setState(() {})),
              const SizedBox(height: Gap.xl),
              PrimaryButton(
                label: AppStrings.submitReturn,
                loading: isBusy('submit'),
                onPressed: isAnyBusy ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
