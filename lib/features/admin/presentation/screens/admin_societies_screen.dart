import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/async_action_mixin.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../society/data/models/society.dart';
import '../../../society/data/models/society_membership.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_product_form.dart' show Validators2;

class AdminSocietiesScreen extends ConsumerWidget {
  const AdminSocietiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingMembershipsProvider).value ?? const [];
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(tabs: [
            const Tab(text: AppStrings.allSocieties),
            Tab(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text(AppStrings.membershipRequests),
                if (pending.isNotEmpty) ...[
                  const SizedBox(width: Gap.s),
                  Badge(label: Text('${pending.length}')),
                ],
              ]),
            ),
          ]),
          const Expanded(
            child: TabBarView(children: [_SocietiesTab(), _RequestsTab()]),
          ),
        ],
      ),
    );
  }
}

class _SocietiesTab extends ConsumerWidget {
  const _SocietiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final societies = ref.watch(adminSocietiesProvider);

    Future<void> open([Society? s]) => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          useSafeArea: true,
          builder: (_) => _SocietySheet(society: s),
        );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'society',
        onPressed: open,
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.newSociety),
      ),
      body: AdminPage(
        child: AdminAsyncList<Society>(
          value: societies,
          emptyIcon: Icons.apartment_outlined,
          emptyMessage: AppStrings.noSocietiesAdmin,
          onRetry: () => ref.invalidate(adminSocietiesProvider),
          builder: (list) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 96),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: Gap.s),
            itemBuilder: (context, i) {
              final s = list[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  minTileHeight: 64,
                  onTap: () => open(s),
                  leading: const Icon(Icons.apartment_rounded),
                  title: Text(s.name),
                  subtitle: Text([s.code, s.city].where((e) => e.isNotEmpty).join(' · ')),
                  trailing: IconButton(
                    tooltip: AppStrings.delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () async {
                      final yes = await confirmDialog(context,
                          title: AppStrings.confirmDelete,
                          confirmLabel: AppStrings.delete,
                          destructive: true);
                      if (yes) await ref.read(adminRepositoryProvider).deleteSociety(s.id);
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

class _SocietySheet extends ConsumerStatefulWidget {
  const _SocietySheet({this.society});

  final Society? society;

  @override
  ConsumerState<_SocietySheet> createState() => _SocietySheetState();
}

class _SocietySheetState extends ConsumerState<_SocietySheet>
    with AsyncActionMixin<_SocietySheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.society?.name);
  late final _code = TextEditingController(text: widget.society?.code);
  late final _address = TextEditingController(text: widget.society?.address);
  late final _city = TextEditingController(text: widget.society?.city);
  late bool _securityDesk = widget.society?.securityDeskIsDefaultReceiver ?? false;

  @override
  void dispose() {
    for (final c in [_name, _code, _address, _city]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await runAction('save', () async {
      final repo = ref.read(adminRepositoryProvider);
      final code = _code.text.trim().toUpperCase();
      if (await repo.isCodeTaken(code, widget.society?.id ?? '')) {
        throw const AppException(AppStrings.errCodeTaken);
      }
      await repo.saveSociety(Society(
        id: widget.society?.id ?? '',
        name: _name.text.trim(),
        address: _address.text.trim(),
        city: _city.text.trim(),
        code: code,
        securityDeskIsDefaultReceiver: _securityDesk,
        createdAt: widget.society?.createdAt,
      ));
    });
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
            Text(widget.society == null ? AppStrings.newSociety : AppStrings.editSociety,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: Gap.l),
            AppTextField(
              controller: _name,
              label: AppStrings.societyName,
              textCapitalization: TextCapitalization.words,
              validator: Validators2.required,
            ),
            const SizedBox(height: Gap.m),
            AppTextField(
              controller: _code,
              label: AppStrings.societyCode,
              helper: AppStrings.societyCodeHelp,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => RegExp(r'^[A-Za-z0-9]{4,20}$').hasMatch((v ?? '').trim())
                  ? null
                  : AppStrings.errCodeFormat,
            ),
            const SizedBox(height: Gap.m),
            AppTextField(
              controller: _address,
              label: AppStrings.address,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: Gap.m),
            AppTextField(
              controller: _city,
              label: AppStrings.city,
              textCapitalization: TextCapitalization.words,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(AppStrings.securityDeskReceiver),
              value: _securityDesk,
              onChanged: (v) => setState(() => _securityDesk = v),
            ),
            const SizedBox(height: Gap.m),
            PrimaryButton(label: AppStrings.save, loading: isBusy('save'), onPressed: isAnyBusy ? null : _save),
          ]),
        ),
      ),
    );
  }
}

class _RequestsTab extends ConsumerWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingMembershipsProvider);

    Future<void> decide(SocietyMembership m, bool approve) async {
      try {
        await ref
            .read(adminRepositoryProvider)
            .setMembershipStatus(m.userId, approve ? 'approved' : 'rejected');
        if (context.mounted) showInfoSnackBar(context, AppStrings.membershipUpdated);
      } catch (e) {
        final msg = ErrorMapper.message(e);
        if (context.mounted && msg != null) showErrorSnackBar(context, msg);
      }
    }

    return AdminPage(
      child: AdminAsyncList<SocietyMembership>(
        value: pending,
        emptyIcon: Icons.how_to_reg_outlined,
        emptyMessage: AppStrings.noRequests,
        onRetry: () => ref.invalidate(pendingMembershipsProvider),
        builder: (list) => ListView.separated(
          padding: const EdgeInsets.all(Gap.m),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: Gap.s),
          itemBuilder: (context, i) {
            final m = list[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(Gap.m),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.societyName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${AppStrings.flatNumber}: ${m.flatLabel}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ]),
                  ),
                  IconButton.filledTonal(
                    tooltip: AppStrings.approve,
                    icon: const Icon(Icons.check_rounded),
                    onPressed: () => decide(m, true),
                  ),
                  const SizedBox(width: Gap.s),
                  IconButton.outlined(
                    tooltip: AppStrings.reject,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => decide(m, false),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
