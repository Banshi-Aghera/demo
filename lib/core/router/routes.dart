class Routes {
  Routes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const forgotPassword = '/forgot-password';
  static const joinSociety = '/join-society';
  static const home = '/home';
  static const admin = '/admin';
  static const product = '/product/:id';
  static const category = '/category/:id';
  static const search = '/search';
  static const wishlist = '/wishlist';

  static const checkout = '/checkout';
  static const orderSuccess = '/order-success/:id';
  static const orders = '/orders';
  static const order = '/orders/:id';
  static const orderReturn = '/orders/:id/return';
  static const addresses = '/addresses';
  static const addressForm = '/addresses/edit';
  static const notifications = '/notifications';
  static const notificationSettings = '/notification-settings';

  static String productPath(String id) => '/product/$id';
  static String orderPath(String id) => '/orders/$id';
  static String orderSuccessPath(String id) => '/order-success/$id';
  static String orderReturnPath(String id) => '/orders/$id/return';
  static String categoryPath(String id) => '/category/$id';

  /// Screens a logged-out user may visit.
  static const publicRoutes = {
    onboarding,
    login,
    register,
    otp,
    forgotPassword,
  };
}
