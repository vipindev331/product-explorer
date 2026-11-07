import 'package:flutter_test/flutter_test.dart';
import 'package:product_explorer/data/datasources/product_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'unrelated': 'keep me'}));

  test('writes, reads and clears cached responses', () async {
    final preferences = await SharedPreferences.getInstance();
    final cache = SharedPreferencesProductCache(preferences);

    expect(await cache.read('products|page=0'), isNull);

    await cache.write('products|page=0', '{"products":[]}');
    expect(await cache.read('products|page=0'), '{"products":[]}');

    await cache.clear();
    expect(await cache.read('products|page=0'), isNull);
    expect(preferences.getString('unrelated'), 'keep me');
  });
}
