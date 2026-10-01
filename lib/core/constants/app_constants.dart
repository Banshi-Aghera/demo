class AppConstants {
  AppConstants._();

  static const indiaDialCode = '+91';
  static const otpLength = 6;
  static const otpResendSeconds = 30;
  static const splashDuration = Duration(milliseconds: 1800);
  static const wideBreakpoint = 1000.0;
  static const maxFormWidth = 440.0;
  static const searchDebounce = Duration(milliseconds: 350);
  static const recentlyViewedMax = 12;
  static const homeRailLimit = 10;
  static const bannerAutoScroll = Duration(seconds: 5);
  static const lowStockThreshold = 5;
  static const functionsRegion = 'asia-south1';
  static const returnWindowDays = 7;
  static const maxReturnPhotos = 3;
  static const maxReviewPhotos = 3;
  static const adminPageSize = 25;
  static const maxProductImages = 5;
}

class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
  static const societies = 'societies';
  static const societyMemberships = 'societyMemberships';
  static const products = 'products';
  static const categories = 'categories';
  static const banners = 'banners';
  static const reviews = 'reviews';
  static const carts = 'carts';
  static const wishlists = 'wishlists';
  static const items = 'items';
  static const coupons = 'coupons';
  static const appSettings = 'appSettings';
  static const pricingDoc = 'pricing';
  static const businessDoc = 'business';
  static const addresses = 'addresses';
  static const fcmTokens = 'fcmTokens';
  static const orders = 'orders';
  static const notifications = 'notifications';
  static const dailyStats = 'dailyStats';
}

class PrefKeys {
  PrefKeys._();

  static const onboardingSeen = 'onboarding_seen';
  static const recentlyViewed = 'recently_viewed';
}
