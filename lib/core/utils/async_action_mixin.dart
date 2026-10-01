import 'package:flutter/widgets.dart';

import '../error/error_mapper.dart';
import 'snackbars.dart';

/// Gives a screen per-button loading states and friendly error snackbars.
///
/// Each action has a key ('login', 'google', ...) so only the tapped button
/// shows a spinner, and all buttons are disabled while any action runs.
mixin AsyncActionMixin<T extends StatefulWidget> on State<T> {
  String? _busyAction;

  bool get isAnyBusy => _busyAction != null;
  bool isBusy(String action) => _busyAction == action;

  /// Returns true when [task] finished without throwing.
  Future<bool> runAction(String action, Future<void> Function() task) async {
    if (_busyAction != null) return false;
    setState(() => _busyAction = action);
    try {
      await task();
      return true;
    } catch (error) {
      final message = ErrorMapper.message(error);
      if (mounted && message != null) showErrorSnackBar(context, message);
      return false;
    } finally {
      if (mounted) setState(() => _busyAction = null);
    }
  }
}
