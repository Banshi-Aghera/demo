import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/coupon.dart';
import '../../data/models/pricing_settings.dart';
import '../../data/repositories/cart_repository.dart';
import '../../domain/price_calculator.dart';

part 'cart_providers.g.dart';

@Riverpod(keepAlive: true)
CartRepository cartRepository(Ref ref) =>
    CartRepository(ref.watch(firebaseFirestoreProvider));

@Riverpod(keepAlive: true)
Stream<List<CartItem>> cartItems(Ref ref) async* {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(cartRepositoryProvider).watchCart(user.uid);
}

@Riverpod(keepAlive: true)
int cartCount(Ref ref) => (ref.watch(cartItemsProvider).value ?? const [])
    .fold(0, (a, i) => a + i.quantity);

@Riverpod(keepAlive: true)
Stream<PricingSettings> pricingSettings(Ref ref) =>
    ref.watch(cartRepositoryProvider).watchPricing();

@Riverpod(keepAlive: true)
class AppliedCoupon extends _$AppliedCoupon {
  @override
  Coupon? build() => null;

  /// Looks up and validates a code against the current subtotal.
  Future<void> apply(String code) async {
    final coupon = await ref.read(cartRepositoryProvider).findCoupon(code);
    final subtotal = ref.read(cartSummaryProvider).subtotal;
    final problem = coupon.validate(subtotal);
    if (problem != null) throw AppException(problem);
    state = coupon;
  }

  void remove() => state = null;
}

@Riverpod(keepAlive: true)
CartSummary cartSummary(Ref ref) {
  final items = ref.watch(cartItemsProvider).value ?? const [];
  final settings =
      ref.watch(pricingSettingsProvider).value ?? const PricingSettings();
  final coupon = ref.watch(appliedCouponProvider);
  return PriceCalculator.calculate(
    items: items,
    settings: settings,
    coupon: coupon,
  );
}

/// Cart actions that need the signed-in uid.
@Riverpod(keepAlive: true)
CartActions cartActions(Ref ref) => CartActions(ref);

class CartActions {
  CartActions(this._ref);

  final Ref _ref;

  CartRepository get _repo => _ref.read(cartRepositoryProvider);

  String get _uid {
    final uid = _ref.read(authUserProvider).value?.uid;
    if (uid == null) throw const AppException(AppStrings.errNotSignedIn);
    return uid;
  }

  Future<void> setQuantity(CartItem item, int qty) =>
      _repo.setQuantity(_uid, item, qty);

  Future<void> remove(CartItem item) => _repo.remove(_uid, item.id);

  Future<void> moveToWishlist(CartItem item) =>
      _repo.moveToWishlist(_uid, item);
}
