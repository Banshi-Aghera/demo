import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

/// Stored on the device; it's a personal convenience, not account data.
class RecentlyViewedRepository {
  RecentlyViewedRepository(this._prefs);

  final SharedPreferences _prefs;

  List<String> read() =>
      _prefs.getStringList(PrefKeys.recentlyViewed) ?? const [];

  Future<List<String>> add(String productId) async {
    final ids = [productId, ...read().where((id) => id != productId)];
    final trimmed = ids.take(AppConstants.recentlyViewedMax).toList();
    await _prefs.setStringList(PrefKeys.recentlyViewed, trimmed);
    return trimmed;
  }

  Future<void> clear() => _prefs.remove(PrefKeys.recentlyViewed);
}
