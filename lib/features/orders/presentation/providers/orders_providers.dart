import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/app_order.dart';
import '../../data/repositories/orders_repository.dart';

part 'orders_providers.g.dart';

@Riverpod(keepAlive: true)
OrdersRepository ordersRepository(Ref ref) => OrdersRepository(
      ref.watch(firebaseFirestoreProvider),
      ref.watch(firebaseFunctionsProvider),
    );

@riverpod
Stream<List<AppOrder>> myOrders(Ref ref) async* {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(ordersRepositoryProvider).watchMyOrders(user.uid);
}

@riverpod
Stream<AppOrder?> orderById(Ref ref, String id) =>
    ref.watch(ordersRepositoryProvider).watchOrder(id);
