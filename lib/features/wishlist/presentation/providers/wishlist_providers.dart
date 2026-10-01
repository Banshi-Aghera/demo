import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../catalog/data/models/product.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../data/repositories/wishlist_repository.dart';

part 'wishlist_providers.g.dart';

@Riverpod(keepAlive: true)
WishlistRepository wishlistRepository(Ref ref) =>
    WishlistRepository(ref.watch(firebaseFirestoreProvider));

@Riverpod(keepAlive: true)
Stream<List<String>> wishlistIds(Ref ref) async* {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(wishlistRepositoryProvider).watchIds(user.uid);
}

@riverpod
bool isWishlisted(Ref ref, String productId) =>
    (ref.watch(wishlistIdsProvider).value ?? const []).contains(productId);

@riverpod
Future<List<Product>> wishlistProducts(Ref ref) async {
  final ids = await ref.watch(wishlistIdsProvider.future);
  return ref.watch(catalogRepositoryProvider).productsByIds(ids);
}

/// Returns true when the product was added.
Future<bool> toggleWishlist(WidgetRef ref, String productId) {
  final uid = ref.read(authUserProvider).value?.uid;
  if (uid == null) throw const AppException(AppStrings.errNotSignedIn);
  return ref.read(wishlistRepositoryProvider).toggle(uid, productId);
}
