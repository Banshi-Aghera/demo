import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../society/data/models/society_membership.dart';
import '../../../society/presentation/providers/society_providers.dart';

/// Phase 1 profile: identity, membership status and logout. Addresses,
/// points, lendings and notification settings are added in later phases.
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logoutConfirmTitle),
        content: const Text(AppStrings.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );
    if (yes == true) await ref.read(authRepositoryProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;
    final membership = ref.watch(myMembershipProvider).value;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (statusText, statusColor) = switch (membership?.status) {
      MembershipStatus.approved => (AppStrings.statusApproved, AppColors.success),
      MembershipStatus.pending => (AppStrings.statusPending, AppColors.warning),
      MembershipStatus.rejected => (AppStrings.statusRejected, AppColors.danger),
      null => (AppStrings.notJoined, scheme.onSurfaceVariant),
    };

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profile)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.m),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: scheme.primary,
                    child: Text(
                      user?.initials ?? '?',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: scheme.onPrimary),
                    ),
                  ),
                  const SizedBox(width: Gap.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (user?.fullName.isNotEmpty ?? false)
                              ? user!.fullName
                              : AppStrings.addYourName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if ((user?.email ?? '').isNotEmpty)
                          Text(user!.email,
                              style:
                                  TextStyle(color: scheme.onSurfaceVariant)),
                        if ((user?.phone ?? '').isNotEmpty)
                          Text(user!.phone,
                              style:
                                  TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Gap.m),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              minTileHeight: 64,
              leading: const Icon(Icons.apartment_rounded),
              title: const Text(AppStrings.societyMembership),
              subtitle: Text(
                membership == null
                    ? statusText
                    : '${membership.societyName} · ${membership.flatLabel}',
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Gap.s + 2, vertical: Gap.xs),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              onTap: membership == null ||
                      membership.status == MembershipStatus.rejected
                  ? () => context.push(Routes.joinSociety)
                  : null,
            ),
          ),
          const SizedBox(height: Gap.m),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (final (icon, label, route) in const [
                (Icons.receipt_long_outlined, AppStrings.myOrders, Routes.orders),
                (Icons.location_on_outlined, AppStrings.addresses, Routes.addresses),
                (Icons.favorite_border_rounded, AppStrings.wishlist, Routes.wishlist),
                (Icons.notifications_none_rounded, AppStrings.notifications, Routes.notifications),
                (Icons.tune_rounded, AppStrings.notificationSettings, Routes.notificationSettings),
              ])
                ListTile(
                  minTileHeight: 56,
                  leading: Icon(icon),
                  title: Text(label),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(route),
                ),
            ]),
          ),
          const SizedBox(height: Gap.m),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              minTileHeight: 56,
              leading: Icon(Icons.logout_rounded, color: scheme.error),
              title: Text(AppStrings.logout,
                  style: TextStyle(color: scheme.error)),
              onTap: () => _confirmLogout(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
