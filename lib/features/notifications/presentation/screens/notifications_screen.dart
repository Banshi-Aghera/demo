import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(myNotificationsProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final repo = ref.read(notificationsRepositoryProvider);
    final fmt = DateFormat('d MMM, h:mm a');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => repo.markAllRead(list.value ?? const []),
              child: const Text(AppStrings.markAllRead),
            ),
          IconButton(
            tooltip: AppStrings.notificationSettings,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(Routes.notificationSettings),
          ),
        ],
      ),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => EmptyState(
          icon: Icons.wifi_off_rounded,
          title: AppStrings.errGeneric,
          message: AppStrings.errNoInternet,
          actionLabel: AppStrings.retry,
          onAction: () => ref.invalidate(myNotificationsProvider),
        ),
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: AppStrings.noNotificationsTitle,
                message: AppStrings.noNotificationsBody,
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: Gap.s),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, i) {
                  final n = items[i];
                  return ListTile(
                    minTileHeight: 72,
                    tileColor: n.read ? null : scheme.primary.withValues(alpha: 0.06),
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: 0.12),
                      child: Icon(
                        n.type == 'order' ? Icons.local_shipping_outlined : Icons.local_offer_outlined,
                        color: scheme.primary,
                      ),
                    ),
                    title: Text(n.title,
                        style: TextStyle(fontWeight: n.read ? FontWeight.w500 : FontWeight.w700)),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n.body),
                      if (n.createdAt != null)
                        Text(fmt.format(n.createdAt!),
                            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ]),
                    onTap: () {
                      if (!n.read) repo.markRead(n.id);
                      if (n.orderId != null && n.orderId!.isNotEmpty) {
                        context.push(Routes.orderPath(n.orderId!));
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
