import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_strings.dart';
import '../providers/connectivity_provider.dart';
import '../theme/app_spacing.dart';

/// Wraps the whole app and shows a slim banner while the device is offline.
class OfflineAware extends ConsumerWidget {
  const OfflineAware({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).value ?? true;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(child: child),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: online
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: scheme.inverseSurface,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Gap.m, vertical: Gap.s + 2),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 18, color: scheme.onInverseSurface),
                          const SizedBox(width: Gap.s),
                          Expanded(
                            child: Text(
                              AppStrings.offline,
                              style: TextStyle(
                                  color: scheme.onInverseSurface,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
