import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/utils/timestamp_converter.dart';

part 'app_order.freezed.dart';
part 'app_order.g.dart';

enum OrderStatus {
  pendingPayment,
  placed,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  returnRequested,
  returned,
}

enum PaymentMethod { razorpay, cod }

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded,
  refundPending,
  codPending,
  codCollected,
}

@freezed
abstract class OrderLine with _$OrderLine {
  const factory OrderLine({
    required String productId,
    String? variantId,
    String? variantLabel,
    required String name,
    String? imageUrl,
    required double unitPrice,
    required double mrp,
    @Default(18) double gstRate,
    required int quantity,
    required double lineTotal,
    required double netAmount,
    required double taxableValue,
    required double taxAmount,
    @Default(false) bool reviewed,
  }) = _OrderLine;

  factory OrderLine.fromJson(Map<String, dynamic> json) =>
      _$OrderLineFromJson(json);
}

@freezed
abstract class OrderPricing with _$OrderPricing {
  const factory OrderPricing({
    @Default(0) int itemCount,
    @Default(0) double mrpTotal,
    @Default(0) double productDiscount,
    @Default(0) double subtotal,
    String? couponCode,
    @Default(0) double couponDiscount,
    @Default(0) double deliveryFee,
    @Default(0) double deliveryTaxable,
    @Default(0) double deliveryTax,
    @Default(0) double gstIncluded,
    @Default(0) double grandTotal,
  }) = _OrderPricing;

  factory OrderPricing.fromJson(Map<String, dynamic> json) =>
      _$OrderPricingFromJson(json);
}

@freezed
abstract class StatusEntry with _$StatusEntry {
  const factory StatusEntry({
    @JsonKey(unknownEnumValue: OrderStatus.placed) required OrderStatus status,
    @TimestampConverter() DateTime? at,
    String? note,
  }) = _StatusEntry;

  factory StatusEntry.fromJson(Map<String, dynamic> json) =>
      _$StatusEntryFromJson(json);
}

@freezed
abstract class OrderAddress with _$OrderAddress {
  const OrderAddress._();

  const factory OrderAddress({
    @Default('') String fullName,
    @Default('') String phone,
    @Default('') String line1,
    @Default('') String line2,
    @Default('') String landmark,
    @Default('') String city,
    @Default('') String state,
    @Default('') String stateCode,
    @Default('') String pincode,
  }) = _OrderAddress;

  factory OrderAddress.fromJson(Map<String, dynamic> json) =>
      _$OrderAddressFromJson(json);

  String get formatted => [
        line1,
        if (line2.isNotEmpty) line2,
        if (landmark.isNotEmpty) landmark,
        '$city, $state $pincode',
      ].join('\n');
}

@freezed
abstract class SellerInfo with _$SellerInfo {
  const factory SellerInfo({
    @Default('') String legalName,
    @Default('') String gstin,
    @Default('') String addressLine,
    @Default('') String city,
    @Default('') String state,
    @Default('') String stateCode,
    @Default('') String pincode,
    @Default('') String email,
    @Default('') String phone,
  }) = _SellerInfo;

  factory SellerInfo.fromJson(Map<String, dynamic> json) =>
      _$SellerInfoFromJson(json);
}

@freezed
abstract class ReturnRequest with _$ReturnRequest {
  const factory ReturnRequest({
    required String reason,
    @Default('') String comment,
    @Default(<String>[]) List<String> photoUrls,
    @TimestampConverter() DateTime? requestedAt,
    @Default('requested') String status,
  }) = _ReturnRequest;

  factory ReturnRequest.fromJson(Map<String, dynamic> json) =>
      _$ReturnRequestFromJson(json);
}

/// Written only by Cloud Functions; the app reads it.
@freezed
abstract class AppOrder with _$AppOrder {
  const AppOrder._();

  const factory AppOrder({
    required String id,
    required String orderNumber,
    @Default('') String invoiceNumber,
    required String userId,
    @Default('') String customerName,
    @Default('') String customerEmail,
    @Default('') String customerPhone,
    @Default(<OrderLine>[]) List<OrderLine> items,
    @Default(OrderAddress()) OrderAddress address,
    @Default('standard') String deliveryOption,
    @JsonKey(unknownEnumValue: PaymentMethod.cod)
    @Default(PaymentMethod.cod)
    PaymentMethod paymentMethod,
    @JsonKey(unknownEnumValue: PaymentStatus.pending)
    @Default(PaymentStatus.pending)
    PaymentStatus paymentStatus,
    @JsonKey(unknownEnumValue: OrderStatus.placed)
    @Default(OrderStatus.placed)
    OrderStatus status,
    @Default(<StatusEntry>[]) List<StatusEntry> statusHistory,
    @Default(OrderPricing()) OrderPricing pricing,
    @Default('intra') String taxType,
    SellerInfo? seller,
    String? cancelReason,
    ReturnRequest? returnRequest,
    @TimestampConverter() DateTime? deliveredAt,
    @TimestampConverter() DateTime? createdAt,
  }) = _AppOrder;

  factory AppOrder.fromJson(Map<String, dynamic> json) =>
      _$AppOrderFromJson(json);

  bool get canCancel => const {
        OrderStatus.pendingPayment,
        OrderStatus.placed,
        OrderStatus.packed,
      }.contains(status);

  bool get awaitingPayment =>
      status == OrderStatus.pendingPayment &&
      paymentMethod == PaymentMethod.razorpay;

  bool canRequestReturn(DateTime now, int windowDays) {
    if (status != OrderStatus.delivered || returnRequest != null) return false;
    final at = deliveredAt;
    return at != null && now.difference(at).inDays < windowDays;
  }

  bool get canReview => const {
        OrderStatus.delivered,
        OrderStatus.returnRequested,
        OrderStatus.returned,
      }.contains(status);

  /// An invoice exists once the order is confirmed (not for unpaid orders).
  bool get hasInvoice =>
      status != OrderStatus.pendingPayment &&
      !(status == OrderStatus.cancelled &&
          (paymentStatus == PaymentStatus.failed ||
              paymentStatus == PaymentStatus.pending));

  DateTime? timeOf(OrderStatus s) {
    for (final e in statusHistory.reversed) {
      if (e.status == s) return e.at;
    }
    return null;
  }
}
