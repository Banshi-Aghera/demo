import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/society.dart';
import '../../data/models/society_membership.dart';
import '../../data/models/group_deal.dart';
import '../../data/repositories/society_repository.dart';

part 'society_providers.g.dart';

@Riverpod(keepAlive: true)
SocietyRepository societyRepository(Ref ref) =>
    SocietyRepository(ref.watch(firebaseFirestoreProvider));

/// The signed-in user's membership (null if they never asked to join).
@Riverpod(keepAlive: true)
Stream<SocietyMembership?> myMembership(Ref ref) async* {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) {
    yield null;
    return;
  }
  yield* ref.watch(societyRepositoryProvider).watchMembership(user.uid);
}
@riverpod
Stream<List<GroupDeal>> groupDeals(Ref ref) {
  final membership = ref.watch(myMembershipProvider).valueOrNull;
  if (membership == null || !membership.isApproved) return Stream.value([]);
  
  final repo = ref.watch(societyRepositoryProvider);
  return repo.watchGroupDeals(membership.societyId).map((list) {
    return list.map((json) {
      try {
        return GroupDeal.fromJson(json);
      } catch (e) {
        return null;
      }
    }).whereType<GroupDeal>().toList();
  });
}
@riverpod
Future<List<Society>> societySearch(Ref ref, String query) =>
    ref.watch(societyRepositoryProvider).searchByName(query);
