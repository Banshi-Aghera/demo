import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
      ref.watch(firebaseAuthProvider),
      ref.watch(firebaseFirestoreProvider),
    );

/// The Firebase Auth user (null when logged out).
@Riverpod(keepAlive: true)
Stream<User?> authUser(Ref ref) =>
    ref.watch(authRepositoryProvider).authStateChanges();

/// The Firestore profile of the signed-in user, including their role.
/// Re-subscribes automatically whenever the auth user changes.
@Riverpod(keepAlive: true)
Stream<AppUser?> currentAppUser(Ref ref) async* {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) {
    yield null;
    return;
  }
  yield* ref.watch(authRepositoryProvider).watchUser(user.uid);
}

/// True between a successful registration and the "Join your society" step,
/// so the router sends new users there instead of straight to Home.
@Riverpod(keepAlive: true)
class PostRegisterFlow extends _$PostRegisterFlow {
  @override
  bool build() => false;

  void start() => state = true;
  void finish() => state = false;
}
