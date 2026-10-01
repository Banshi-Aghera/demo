import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _query = '';

  Future<void> _update(AppUser user, {bool? blocked, String? role}) async {
    final me = ref.read(authUserProvider).value?.uid;
    if (user.uid == me) {
      showErrorSnackBar(context, AppStrings.cannotEditSelf);
      return;
    }
    final label = blocked != null
        ? (blocked ? AppStrings.blockUser : AppStrings.unblockUser)
        : (role == 'admin' ? AppStrings.makeAdmin : AppStrings.removeAdmin);
    final yes = await confirmDialog(context,
        title: '$label — ${user.displayName}',
        body: blocked == true ? AppStrings.blockUserBody : null,
        confirmLabel: label,
        destructive: blocked == true);
    if (!yes) return;
    try {
      await ref.read(adminRepositoryProvider).setUserFlags(user.uid, blocked: blocked, role: role);
      if (mounted) showInfoSnackBar(context, AppStrings.userUpdated);
    } catch (e) {
      final msg = ErrorMapper.message(e);
      if (mounted && msg != null) showErrorSnackBar(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(adminUsersProvider);
    final q = _query.toLowerCase();

    return AdminPage(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Gap.m),
            child: AdminSearchField(
              hint: AppStrings.searchUsers,
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: AdminAsyncList<AppUser>(
              value: users,
              emptyIcon: Icons.people_outline_rounded,
              emptyMessage: AppStrings.noResults,
              onRetry: () => ref.invalidate(adminUsersProvider),
              builder: (all) {
                final list = q.isEmpty
                    ? all
                    : all
                        .where((u) =>
                            u.fullName.toLowerCase().contains(q) ||
                            u.email.toLowerCase().contains(q) ||
                            u.phone.contains(q))
                        .toList();
                if (list.isEmpty) return const Center(child: Text(AppStrings.noResults));
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(Gap.m, 0, Gap.m, Gap.xl),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Gap.s),
                  itemBuilder: (context, i) {
                    final u = list[i];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        minTileHeight: 72,
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          useSafeArea: true,
                          builder: (_) => _UserSheet(user: u),
                        ),
                        leading: CircleAvatar(child: Text(u.initials)),
                        title: Row(children: [
                          Flexible(
                            child: Text(u.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          if (u.isAdmin) ...[
                            const SizedBox(width: Gap.s),
                            _Tag(label: AppStrings.roleAdmin, color: AppColors.primary),
                          ],
                          if (u.blocked) ...[
                            const SizedBox(width: Gap.s),
                            _Tag(label: AppStrings.blocked, color: AppColors.danger),
                          ],
                        ]),
                        subtitle: Text(
                          [if (u.email.isNotEmpty) u.email, if (u.phone.isNotEmpty) u.phone].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) => switch (v) {
                            'block' => _update(u, blocked: true),
                            'unblock' => _update(u, blocked: false),
                            'admin' => _update(u, role: 'admin'),
                            _ => _update(u, role: 'customer'),
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: u.blocked ? 'unblock' : 'block',
                              child: Text(u.blocked ? AppStrings.unblockUser : AppStrings.blockUser),
                            ),
                            PopupMenuItem(
                              value: u.isAdmin ? 'customer' : 'admin',
                              child: Text(u.isAdmin ? AppStrings.removeAdmin : AppStrings.makeAdmin),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
      );
}

class _UserSheet extends ConsumerWidget {
  const _UserSheet({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersOfUserProvider(user.uid));
    final dateFmt = DateFormat('d MMM yyyy');
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(user.displayName,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (user.email.isNotEmpty) Text(user.email),
          if (user.phone.isNotEmpty) Text(user.phone),
          if (user.createdAt != null)
            Text('${AppStrings.joined} ${dateFmt.format(user.createdAt!)}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          const Divider(height: Gap.l),
          Text(AppStrings.userOrders, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: Gap.s),
          orders.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Text(AppStrings.errGeneric),
            data: (list) => list.isEmpty
                ? const Text(AppStrings.noOrdersTitle)
                : Column(children: [
                    for (final o in list.take(10))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(o.orderNumber),
                        subtitle: Text(o.createdAt == null ? '' : dateFmt.format(o.createdAt!)),
                        trailing: Text(Money.format(o.pricing.grandTotal),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                  ]),
          ),
        ],
      ),
    );
  }
}
