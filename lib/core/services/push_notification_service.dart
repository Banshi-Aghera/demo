import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/routes.dart';
import '../utils/snackbars.dart';

/// Handles FCM on Android and iOS: permission, token upkeep, and opening
/// the right order when a notification is tapped. (Web push isn't used:
/// the web build is the admin panel.)
class PushNotificationService {
  PushNotificationService({
    required this.router,
    required this.saveToken,
  });

  final GoRouter router;
  final Future<void> Function(String token, String platform) saveToken;

  final _subs = <StreamSubscription<dynamic>>[];
  bool _started = false;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> start() async {
    if (_started || !supported) return;
    _started = true;
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    await messaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);

    final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    final token = await messaging.getToken();
    if (token != null) await saveToken(token, platform);
    _subs.add(messaging.onTokenRefresh.listen((t) => saveToken(t, platform)));

    // App in foreground: the system doesn't show a banner on Android, so
    // show a snackbar with a shortcut to the order.
    _subs.add(FirebaseMessaging.onMessage.listen((m) {
      final title = m.notification?.title;
      if (title == null) return;
      final orderId = m.data['orderId'] as String?;
      rootMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('$title\n${m.notification?.body ?? ''}'),
          action: (orderId?.isNotEmpty ?? false)
              ? SnackBarAction(
                  label: 'View',
                  onPressed: () => router.push(Routes.orderPath(orderId!)),
                )
              : null,
        ),
      );
    }));

    // Tapped while the app was in the background.
    _subs.add(FirebaseMessaging.onMessageOpenedApp.listen(_open));

    // Tapped while the app was closed.
    final initial = await messaging.getInitialMessage();
    if (initial != null) _open(initial);
  }

  void _open(RemoteMessage m) {
    final orderId = m.data['orderId'] as String?;
    if (orderId != null && orderId.isNotEmpty) {
      router.push(Routes.orderPath(orderId));
    } else {
      router.push(Routes.notifications);
    }
  }

  /// Call before sign-out so this device stops getting the old user's pushes.
  static Future<String?> currentToken() async {
    if (!supported) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _started = false;
  }
}
