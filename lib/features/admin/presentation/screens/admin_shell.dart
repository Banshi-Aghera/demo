import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/admin_providers.dart';
import 'admin_catalog_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_societies_screen.dart';
import 'admin_users_screen.dart';

class _AdminSection {
  const _AdminSection(this.label, this.icon, this.builder);
  final String label;
  final IconData icon;
  final Widget Function() builder;
}

final _sections = <_AdminSection>[
  _AdminSection(AppStrings.adminDashboard, Icons.dashboard_rounded,
      () => const AdminDashboardScreen()),
  _AdminSection(AppStrings.adminProducts, Icons.inventory_2_rounded,
      () => const AdminProductsScreen()),
  _AdminSection(AppStrings.adminCategories, Icons.category_rounded,
      () => const AdminCatalogScreen()),
  _AdminSection(AppStrings.adminOrders, Icons.receipt_long_rounded,
      () => const AdminOrdersScreen()),
  _AdminSection(AppStrings.adminUsers, Icons.people_alt_rounded,
      () => const AdminUsersScreen()),
  _AdminSection(AppStrings.adminSocieties, Icons.apartment_rounded,
      () => const AdminSocietiesScreen()),
  _AdminSection(AppStrings.adminNeighbourDrop, Icons.local_shipping_rounded,
      () => const _ComingSoon(AppStrings.adminNeighbourDrop, Icons.local_shipping_rounded)),
  _AdminSection(AppStrings.adminLending, Icons.handshake_rounded,
      () => const _ComingSoon(AppStrings.adminLending, Icons.handshake_rounded)),
  _AdminSection(AppStrings.adminGroupBuy, Icons.groups_rounded,
      () => const _ComingSoon(AppStrings.adminGroupBuy, Icons.groups_rounded)),
  _AdminSection(AppStrings.adminCoupons, Icons.local_offer_rounded,
      () => const AdminCouponsScreen()),
  _AdminSection(AppStrings.adminSettings, Icons.settings_rounded,
      () => const AdminSettingsScreen()),
  _AdminSection(AppStrings.adminReports, Icons.download_rounded,
      () => const AdminReportsScreen()),
];

/// Responsive admin frame: fixed side nav on wide screens, drawer on mobile.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _selected = 0;

  void _select(int i, {bool closeDrawer = false}) {
    setState(() => _selected = i);
    if (closeDrawer) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selected];
    final pendingRequests =
        (ref.watch(pendingMembershipsProvider).value ?? const []).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppConstants.wideBreakpoint;
        // KeyedSubtree keeps each section's state while switching.
        final body = KeyedSubtree(
          key: ValueKey(_selected),
          child: section.builder(),
        );

        if (wide) {
          return Scaffold(
            body: Row(children: [
              SizedBox(
                width: 264,
                child: _SideNav(
                  selected: _selected,
                  onSelect: _select,
                  pendingRequests: pendingRequests,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(section.label),
                    actions: const [_LogoutButton(), SizedBox(width: Gap.s)],
                  ),
                  body: body,
                ),
              ),
            ]),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(section.label),
            actions: const [_LogoutButton()],
          ),
          drawer: Drawer(
            child: _SideNav(
              selected: _selected,
              onSelect: (i) => _select(i, closeDrawer: true),
              pendingRequests: pendingRequests,
            ),
          ),
          body: body,
        );
      },
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon(this.title, this.icon);

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => EmptyState(
        icon: icon,
        title: title,
        message: AppStrings.adminSectionComing,
      );
}

class _SideNav extends ConsumerWidget {
  const _SideNav({
    required this.selected,
    required this.onSelect,
    required this.pendingRequests,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final int pendingRequests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = ref.watch(currentAppUserProvider).value;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Gap.l),
              child: Row(children: [
                const AppLogo(size: 40),
                const SizedBox(width: Gap.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppStrings.appName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(AppStrings.adminPanel,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: Gap.s),
                itemCount: _sections.length,
                itemBuilder: (context, i) {
                  final s = _sections[i];
                  final isSelected = i == selected;
                  final showBadge =
                      s.label == AppStrings.adminSocieties && pendingRequests > 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      minTileHeight: Gap.tapTarget,
                      selected: isSelected,
                      selectedTileColor: scheme.primary.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      leading: Icon(s.icon),
                      title: Text(s.label),
                      trailing: showBadge
                          ? Badge(label: Text('$pendingRequests'))
                          : null,
                      onTap: () => onSelect(i),
                    ),
                  );
                },
              ),
            ),
            if (user != null)
              Padding(
                padding: const EdgeInsets.all(Gap.m),
                child: Text(
                  '${AppStrings.signedInAs} ${user.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
        tooltip: AppStrings.logout,
        icon: const Icon(Icons.logout_rounded),
        onPressed: () => ref.read(authRepositoryProvider).signOut(),
      );
}
