import 'package:flutter/material.dart';

/// Lets services (e.g. push notifications) show snackbars without a context.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showErrorSnackBar(BuildContext context, String message) {
  final scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: scheme.error,
      ),
    );
}

void showInfoSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
