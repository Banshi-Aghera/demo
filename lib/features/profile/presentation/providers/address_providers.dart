import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/address.dart';
import '../../data/repositories/address_repository.dart';

part 'address_providers.g.dart';

@Riverpod(keepAlive: true)
AddressRepository addressRepository(Ref ref) =>
    AddressRepository(ref.watch(firebaseFirestoreProvider));

@Riverpod(keepAlive: true)
Stream<List<Address>> addresses(Ref ref) async* {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(addressRepositoryProvider).watch(user.uid);
}
