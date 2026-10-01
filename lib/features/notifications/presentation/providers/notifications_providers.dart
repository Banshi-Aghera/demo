import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notifications_repository.dart';

part 'notifications_providers.g.dart';

@Riverpod(keepAlive: true)
NotificationsRepository notificationsRepository(Ref ref) =>
    NotificationsRepository(ref.watch(firebaseFirestoreProvider));

@Riverpod(keepAlive: true)
Stream<List<AppNotification>> myNotifications(Ref ref) async* {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref.watch(notificationsRepositoryProvider).watch(user.uid);
}

@Riverpod(keepAlive: true)
int unreadNotificationCount(Ref ref) =>
    (ref.watch(myNotificationsProvider).value ?? const [])
        .where((n) => !n.read)
        .length;
