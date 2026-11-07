import 'package:shared_preferences/shared_preferences.dart';

/// Key-value store for previously fetched API responses (offline support).
abstract interface class ProductLocalDataSource {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> clear();
}

class SharedPreferencesProductCache implements ProductLocalDataSource {
  SharedPreferencesProductCache(this._preferences);

  static const _prefix = 'product_cache::';

  final SharedPreferences _preferences;

  @override
  Future<String?> read(String key) async => _preferences.getString('$_prefix$key');

  @override
  Future<void> write(String key, String value) async {
    await _preferences.setString('$_prefix$key', value);
  }

  @override
  Future<void> clear() async {
    final keys = _preferences.getKeys().where((key) => key.startsWith(_prefix)).toList();
    for (final key in keys) {
      await _preferences.remove(key);
    }
  }
}
