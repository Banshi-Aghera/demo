import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/snackbars.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/notifications_providers.dart';

/// Preferences live on users/{uid}.notificationPrefs; Cloud Functions check
/// them before sending a push.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).value;
    final prefs = user?.notificationPrefs ?? const <String, bool>{};

    Future<void> toggle(String key, bool value) async {
      if (user == null) return;
      try {
        await ref.read(notificationsRepositoryProvider).setPreference(user.uid, key, value);
      } catch (e) {
        final msg = ErrorMapper.message(e);
        if (context.mounted && msg != null) showErrorSnackBar(context, msg);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.notificationSettings)),
      body: ListView(
        padding: const EdgeInsets.all(Gap.m),
        children: [
          Card(
            child: Column(children: [
              SwitchListTile(
                title: const Text(AppStrings.notifOrderUpdates),
                subtitle: const Text(AppStrings.notifOrderUpdatesBody),
                value: prefs['orderUpdates'] ?? true,
                onChanged: (v) => toggle('orderUpdates', v),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text(AppStrings.notifOffers),
                subtitle: const Text(AppStrings.notifOffersBody),
                value: prefs['offers'] ?? true,
                onChanged: (v) => toggle('offers', v),
              ),
            ]),
          ),
          const SizedBox(height: Gap.m),
          Text(AppStrings.notifSettingsNote,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
