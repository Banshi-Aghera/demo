import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../router/app_router.dart';
import '../services/push_notification_service.dart';

part 'push_providers.g.dart';

/// Starts push notifications for the signed-in customer. Watched by the
/// customer shell, so it runs once a customer reaches Home.
@Riverpod(keepAlive: true)
Future<void> pushSetup(Ref ref) async {
  final user = await ref.watch(authUserProvider.future);
  if (user == null) return;
  final service = PushNotificationService(
    router: ref.read(appRouterProvider),
    saveToken: (token, platform) => ref
        .read(notificationsRepositoryProvider)
        .saveToken(user.uid, token, platform),
  );
  ref.onDispose(service.dispose);
  await service.start();
}
