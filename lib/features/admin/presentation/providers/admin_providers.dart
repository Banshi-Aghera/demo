import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/data/models/app_user.dart';
import '../../../cart/data/models/coupon.dart';
import '../../../catalog/data/models/product.dart';
import '../../../orders/data/models/app_order.dart';
import '../../../society/data/models/society.dart';
import '../../../society/data/models/society_membership.dart';
import '../../data/models/business_settings.dart';
import '../../data/models/daily_stat.dart';
import '../../data/repositories/admin_repository.dart';

part 'admin_providers.g.dart';

@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) => AdminRepository(
      ref.watch(firebaseFirestoreProvider),
      ref.watch(firebaseFunctionsProvider),
    );

@riverpod
Future<List<DailyStat>> dailyStats(Ref ref, int days) =>
    ref.watch(adminRepositoryProvider).dailyStats(days);

@riverpod
Future<int> newUsersCount(Ref ref) =>
    ref.watch(adminRepositoryProvider).newUsersCount(7);

@riverpod
Future<int> pendingOrdersCount(Ref ref) =>
    ref.watch(adminRepositoryProvider).pendingOrdersCount();

@riverpod
Future<List<Product>> lowStockProducts(Ref ref) =>
    ref.watch(adminRepositoryProvider).lowStockProducts();

@riverpod
Stream<List<Product>> adminProducts(Ref ref) =>
    ref.watch(adminRepositoryProvider).watchProducts();

@riverpod
Stream<List<AppOrder>> adminOrders(Ref ref, String? status) =>
    ref.watch(adminRepositoryProvider).watchOrders(status: status);

@riverpod
Stream<List<AppUser>> adminUsers(Ref ref) =>
    ref.watch(adminRepositoryProvider).watchUsers();

@riverpod
Future<List<AppOrder>> ordersOfUser(Ref ref, String userId) =>
    ref.watch(adminRepositoryProvider).ordersOfUser(userId);

@riverpod
Stream<List<Society>> adminSocieties(Ref ref) =>
    ref.watch(adminRepositoryProvider).watchSocieties();

@riverpod
Stream<List<SocietyMembership>> pendingMemberships(Ref ref) =>
    ref.watch(adminRepositoryProvider).watchMemberships('pending');

@riverpod
Stream<List<Coupon>> adminCoupons(Ref ref) =>
    ref.watch(adminRepositoryProvider).watchCoupons();

@riverpod
Stream<BusinessSettings> businessSettings(Ref ref) =>
    ref.watch(adminRepositoryProvider).watchBusiness();

@riverpod
Stream<RewardSettings> rewardSettings(Ref ref) =>
    ref.watch(adminRepositoryProvider).watchRewards();
