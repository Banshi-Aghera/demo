import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/repositories/checkout_repository.dart';
import '../../data/repositories/razorpay_service.dart';

part 'checkout_providers.g.dart';

@Riverpod(keepAlive: true)
CheckoutRepository checkoutRepository(Ref ref) =>
    CheckoutRepository(ref.watch(firebaseFunctionsProvider));

@Riverpod(keepAlive: true)
RazorpayService razorpayService(Ref ref) => RazorpayService();
