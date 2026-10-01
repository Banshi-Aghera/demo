import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

part 'prefs_providers.g.dart';

/// Overridden in main() with the loaded instance.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider must be overridden');

@Riverpod(keepAlive: true)
class OnboardingSeen extends _$OnboardingSeen {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool(PrefKeys.onboardingSeen) ??
      false;

  Future<void> markSeen() async {
    await ref
        .read(sharedPreferencesProvider)
        .setBool(PrefKeys.onboardingSeen, true);
    state = true;
  }
}
