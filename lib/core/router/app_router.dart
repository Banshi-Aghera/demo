import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/admin/presentation/screens/admin_shell.dart';
import '../../features/auth/data/models/app_user.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/phone_otp_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/catalog/presentation/screens/product_detail_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/checkout/presentation/screens/order_success_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/orders/presentation/screens/return_request_screen.dart';
import '../../features/profile/data/models/address.dart';
import '../../features/profile/presentation/screens/address_form_screen.dart';
import '../../features/profile/presentation/screens/addresses_screen.dart';
import '../../features/catalog/presentation/screens/product_list_screen.dart';
import '../../features/catalog/presentation/screens/search_screen.dart';
import '../../features/home/presentation/screens/customer_shell.dart';
import '../../features/society/presentation/screens/join_society_screen.dart';
import '../../features/wishlist/presentation/screens/wishlist_screen.dart';
import '../providers/prefs_providers.dart';
import 'routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // Re-run redirects whenever auth, profile, onboarding or sign-up flow changes.
  final refresh = ValueNotifier<int>(0);
  void bump() => refresh.value++;
  ref.listen(authUserProvider, (previous, next) => bump());
  ref.listen(currentAppUserProvider, (previous, next) => bump());
  ref.listen(onboardingSeenProvider, (previous, next) => bump());
  ref.listen(postRegisterFlowProvider, (previous, next) => bump());

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) =>
            _fade(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => _fade(state, const LoginScreen()),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.otp,
        builder: (context, state) => const PhoneOtpScreen(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.joinSociety,
        builder: (context, state) => const JoinSocietyScreen(),
      ),
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) => _fade(state, const CustomerShell()),
      ),
      GoRoute(
        path: Routes.product,
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.category,
        builder: (context, state) =>
            ProductListScreen(categoryId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: Routes.wishlist,
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: Routes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: Routes.orderSuccess,
        pageBuilder: (context, state) => _fade(
            state, OrderSuccessScreen(orderId: state.pathParameters['id']!)),
      ),
      GoRoute(
        path: Routes.orders,
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: Routes.order,
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.orderReturn,
        builder: (context, state) =>
            ReturnRequestScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.addresses,
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: Routes.addressForm,
        builder: (context, state) =>
            AddressFormScreen(address: state.extra as Address?),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: Routes.notificationSettings,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: Routes.admin,
        pageBuilder: (context, state) => _fade(state, const AdminShell()),
      ),
    ],
  );

  ref.onDispose(() {
    refresh.dispose();
    router.dispose();
  });
  return router;
}

String? _redirect(Ref ref, GoRouterState state) {
  final location = state.matchedLocation;

  // The splash screen decides where to go on its own.
  if (location == Routes.splash) return null;

  final firebaseUser = ref.read(authUserProvider).value;
  final isPublic = Routes.publicRoutes.contains(location);

  if (firebaseUser == null) {
    final onboardingSeen = ref.read(onboardingSeenProvider);
    if (!onboardingSeen && location != Routes.onboarding) {
      return Routes.onboarding;
    }
    return isPublic ? null : Routes.login;
  }

  // Signed in, but the Firestore profile hasn't loaded yet: stay put.
  final appUser = ref.read(currentAppUserProvider).value;
  if (appUser == null) return null;

  if (appUser.role == UserRole.admin) {
    return location.startsWith(Routes.admin) ? null : Routes.admin;
  }

  if (ref.read(postRegisterFlowProvider)) {
    return location == Routes.joinSociety ? null : Routes.joinSociety;
  }

  if (location.startsWith(Routes.admin) || isPublic) return Routes.home;
  return null;
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}
