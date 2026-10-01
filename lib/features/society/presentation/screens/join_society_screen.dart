import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/society.dart';
import '../providers/society_providers.dart';

enum _JoinMode { search, code }

class JoinSocietyScreen extends ConsumerStatefulWidget {
  const JoinSocietyScreen({super.key});

  @override
  ConsumerState<JoinSocietyScreen> createState() => _JoinSocietyScreenState();
}

class _JoinSocietyScreenState extends ConsumerState<JoinSocietyScreen>
    with AsyncActionMixin<JoinSocietyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _search = TextEditingController();
  final _code = TextEditingController();
  final _wing = TextEditingController();
  final _flat = TextEditingController();

  _JoinMode _mode = _JoinMode.search;
  String _query = '';
  Timer? _debounce;
  Society? _selected;

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_search, _code, _wing, _flat]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  Future<void> _findByCode() async {
    if (_code.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    await runAction('find', () async {
      final society =
          await ref.read(societyRepositoryProvider).findByCode(_code.text);
      if (society == null) {
        throw const AppException(AppStrings.errSocietyCodeNotFound);
      }
      setState(() => _selected = society);
    });
  }

  Future<void> _submit() async {
    final society = _selected;
    if (society == null) {
      showErrorSnackBar(context, AppStrings.errSelectSociety);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ok = await runAction('submit', () async {
      final uid = ref.read(authUserProvider).value?.uid;
      if (uid == null) throw const AppException(AppStrings.errNotSignedIn);
      await ref.read(societyRepositoryProvider).requestMembership(
            uid: uid,
            society: society,
            wing: _wing.text,
            flatNumber: _flat.text,
          );
    });
    if (!ok || !mounted) return;
    showInfoSnackBar(context, AppStrings.requestSent);
    _leave();
  }

  void _leave() {
    ref.read(postRegisterFlowProvider.notifier).finish();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.joinSocietyTitle),
        actions: [
          TextButton(
            onPressed: isAnyBusy ? null : _leave,
            child: const Text(AppStrings.skipForNow),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppConstants.maxFormWidth),
            child: ListView(
              padding: const EdgeInsets.all(Gap.l),
              children: [
                Text(
                  AppStrings.joinSocietySubtitle,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: Gap.l),
                if (_selected == null) ...[
                  SegmentedButton<_JoinMode>(
                    segments: const [
                      ButtonSegment(
                        value: _JoinMode.search,
                        icon: Icon(Icons.search_rounded),
                        label: Text(AppStrings.searchByName),
                      ),
                      ButtonSegment(
                        value: _JoinMode.code,
                        icon: Icon(Icons.pin_outlined),
                        label: Text(AppStrings.enterCode),
                      ),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                  ),
                  const SizedBox(height: Gap.l),
                  if (_mode == _JoinMode.search)
                    ..._buildSearch()
                  else
                    ..._buildCodeEntry(),
                ] else
                  _SelectedSocietyCard(
                    society: _selected!,
                    onChange: isAnyBusy
                        ? null
                        : () => setState(() => _selected = null),
                  ),
                if (_selected != null) ...[
                  const SizedBox(height: Gap.l),
                  Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _wing,
                            label: AppStrings.wingOrBuilding,
                            textCapitalization: TextCapitalization.characters,
                            validator: Validators.required,
                          ),
                        ),
                        const SizedBox(width: Gap.m),
                        Expanded(
                          child: AppTextField(
                            controller: _flat,
                            label: AppStrings.flatNumber,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            validator: Validators.required,
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Gap.l),
                  PrimaryButton(
                    label: AppStrings.sendRequest,
                    loading: isBusy('submit'),
                    onPressed: isAnyBusy ? null : _submit,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSearch() {
    final results = _query.length >= 2
        ? ref.watch(societySearchProvider(_query))
        : null;

    return [
      AppTextField(
        controller: _search,
        label: AppStrings.searchByName,
        hint: AppStrings.searchSocietyHint,
        prefixIcon: Icons.apartment_rounded,
        textInputAction: TextInputAction.search,
        onChanged: _onSearchChanged,
      ),
      const SizedBox(height: Gap.m),
      if (results != null)
        results.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.l),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _InlineMessage(
            text: AppStrings.errGeneric,
            actionLabel: AppStrings.retry,
            onAction: () => ref.invalidate(societySearchProvider(_query)),
          ),
          data: (list) => list.isEmpty
              ? const _InlineMessage(text: AppStrings.noSocietiesFound)
              : Column(
                  children: [
                    for (final s in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.s),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            minTileHeight: 64,
                            leading: const Icon(Icons.apartment_rounded),
                            title: Text(s.name),
                            subtitle: Text(
                              [s.address, s.city]
                                  .where((e) => e.isNotEmpty)
                                  .join(', '),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => setState(() => _selected = s),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
    ];
  }

  List<Widget> _buildCodeEntry() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AppTextField(
              controller: _code,
              label: AppStrings.enterCode,
              hint: AppStrings.societyCodeHint,
              prefixIcon: Icons.pin_outlined,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _findByCode(),
            ),
          ),
          const SizedBox(width: Gap.s),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(88, 56)),
              onPressed: isAnyBusy ? null : _findByCode,
              child: isBusy('find')
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text(AppStrings.find),
            ),
          ),
        ],
      ),
    ];
  }
}

class _SelectedSocietyCard extends StatelessWidget {
  const _SelectedSocietyCard({required this.society, required this.onChange});

  final Society society;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Gap.m),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.apartment_rounded, color: scheme.primary),
            ),
            const SizedBox(width: Gap.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(society.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    society.code,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onChange, child: const Text(AppStrings.change)),
          ],
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Gap.m),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
