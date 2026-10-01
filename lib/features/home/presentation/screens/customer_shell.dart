import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/push_providers.dart';
import '../../../../core/providers/shell_tab_provider.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../../cart/presentation/screens/cart_tab.dart';
import '../../../catalog/presentation/screens/categories_tab.dart';
import '../../../profile/presentation/screens/profile_tab.dart';
import '../../../society/presentation/screens/my_society_tab.dart';
import 'home_tab.dart';

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key});

  static const _tabs = <Widget>[
    HomeTab(),
    CategoriesTab(),
    MySocietyTab(),
    CartTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If an admin blocks this account mid-session, sign the user out.
    ref.listen<AsyncValue<AppUser?>>(currentAppUserProvider, (prev, next) {
      if (next.value?.blocked == true) {
        ref.read(authRepositoryProvider).signOut();
        showErrorSnackBar(context, AppStrings.errBlocked);
      }
    });

    // Registers this device for order notifications (Android/iOS only).
    ref.watch(pushSetupProvider);

    final tab = ref.watch(shellTabStateProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      body: IndexedStack(index: tab.index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) =>
            ref.read(shellTabStateProvider.notifier).select(ShellTab.values[i]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: AppStrings.navHome,
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: AppStrings.navCategories,
          ),
          const NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment_rounded),
            label: AppStrings.navMySociety,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_rounded),
            ),
            label: AppStrings.navCart,
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: AppStrings.navProfile,
          ),
        ],
      ),
    );
  }
}
