import '../../../core/utils/formatters.dart';
import '../data/models/cart_item.dart';
import '../data/models/coupon.dart';
import '../data/models/pricing_settings.dart';

class CartSummary {
  const CartSummary({
    required this.itemCount,
    required this.mrpTotal,
    required this.productDiscount,
    required this.subtotal,
    required this.couponDiscount,
    required this.deliveryFee,
    required this.gstIncluded,
    required this.grandTotal,
    required this.amountForFreeDelivery,
    this.couponError,
  });

  static const empty = CartSummary(
    itemCount: 0,
    mrpTotal: 0,
    productDiscount: 0,
    subtotal: 0,
    couponDiscount: 0,
    deliveryFee: 0,
    gstIncluded: 0,
    grandTotal: 0,
    amountForFreeDelivery: 0,
  );

  final int itemCount;
  final double mrpTotal;
  final double productDiscount;
  final double subtotal;
  final double couponDiscount;
  final double deliveryFee;
  final double gstIncluded;
  final double grandTotal;

  /// How much more to add for free delivery (0 when already free).
  final double amountForFreeDelivery;

  /// Set when an applied coupon no longer qualifies (e.g. cart shrank).
  final String? couponError;

  double get totalSavings => productDiscount + couponDiscount;
}

class PriceCalculator {
  PriceCalculator._();

  /// [waiveDelivery] is used by Neighbour Drop in later phases.
  static CartSummary calculate({
    required List<CartItem> items,
    required PricingSettings settings,
    Coupon? coupon,
    bool waiveDelivery = false,
  }) {
    if (items.isEmpty) return CartSummary.empty;

    final itemCount = items.fold<int>(0, (a, i) => a + i.quantity);
    final mrpTotal = items.fold<double>(0, (a, i) => a + i.lineMrp);
    final subtotal = items.fold<double>(0, (a, i) => a + i.lineTotal);
    final productDiscount = mrpTotal - subtotal;

    String? couponError;
    double couponDiscount = 0;
    if (coupon != null) {
      couponError = coupon.validate(subtotal);
      if (couponError == null) couponDiscount = coupon.discountFor(subtotal);
    }

    final afterCoupon = subtotal - couponDiscount;
    final qualifiesFree = subtotal >= settings.freeDeliveryAbove;
    final deliveryFee =
        (waiveDelivery || qualifiesFree) ? 0.0 : settings.deliveryFee;

    // GST is inside the prices; spread the coupon proportionally across lines.
    final couponShare = subtotal == 0 ? 0 : couponDiscount / subtotal;
    final gst = items.fold<double>(0, (a, i) {
      final taxable = i.lineTotal * (1 - couponShare);
      return a + taxable * i.gstRate / (100 + i.gstRate);
    });

    return CartSummary(
      itemCount: itemCount,
      mrpTotal: round2(mrpTotal),
      productDiscount: round2(productDiscount),
      subtotal: round2(subtotal),
      couponDiscount: round2(couponDiscount),
      deliveryFee: round2(deliveryFee),
      gstIncluded: round2(gst),
      grandTotal: round2(afterCoupon + deliveryFee),
      amountForFreeDelivery:
          qualifiesFree ? 0 : round2(settings.freeDeliveryAbove - subtotal),
      couponError: couponError,
    );
  }
}
