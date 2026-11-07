import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:product_explorer/core/errors/app_exception.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late InMemoryProductCache cache;

  setUp(() => cache = InMemoryProductCache());

  group('getProducts', () {
    test('returns fresh data from the API and caches it', () async {
      final repository = buildRepository(fakeApiClient(buildCatalogue(3)), cache: cache);

      final result = await repository.getProducts(limit: 20);

      expect(result.isFromCache, isFalse);
      expect(result.data.products, hasLength(3));
      expect(result.data.total, 3);
      expect(cache.store, hasLength(1));
    });

    test('falls back to the cache when offline', () async {
      await buildRepository(fakeApiClient(buildCatalogue(3)), cache: cache)
          .getProducts(limit: 20);

      final offline = buildRepository(offlineClient(), cache: cache);
      final result = await offline.getProducts(limit: 20);

      expect(result.isFromCache, isTrue);
      expect(result.data.products.map((p) => p.title), ['Product 1', 'Product 2', 'Product 3']);
    });

    test('falls back to the cache when the server errors', () async {
      await buildRepository(fakeApiClient(buildCatalogue(2)), cache: cache)
          .getProducts(limit: 20);

      final failing = buildRepository(
        MockClient((_) async => http.Response('oops', 503)),
        cache: cache,
      );
      final result = await failing.getProducts(limit: 20);

      expect(result.isFromCache, isTrue);
      expect(result.data.products, hasLength(2));
    });

    test('caches each page and query separately', () async {
      final online = buildRepository(fakeApiClient(buildCatalogue(5)), cache: cache);
      await online.getProducts(limit: 2);

      final offline = buildRepository(offlineClient(), cache: cache);

      expect(
        offline.getProducts(limit: 2, skip: 2),
        throwsA(isA<NetworkException>()),
      );
      expect(
        offline.getProducts(limit: 2, query: 'phone'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('rethrows a network error when nothing is cached', () {
      final repository = buildRepository(offlineClient(), cache: cache);

      expect(repository.getProducts(), throwsA(isA<NetworkException>()));
    });

    test('reports malformed responses as DataParsingException', () {
      final repository = buildRepository(
        MockClient((_) async => http.Response('<html>not json</html>', 200)),
        cache: cache,
      );

      expect(repository.getProducts(), throwsA(isA<DataParsingException>()));
    });

    test('does not cache malformed responses', () async {
      final repository = buildRepository(
        MockClient((_) async => http.Response('[]', 200)),
        cache: cache,
      );

      await expectLater(repository.getProducts(), throwsA(isA<DataParsingException>()));
      expect(cache.store, isEmpty);
    });
  });

  group('getProduct', () {
    test('fetches a product by id and caches it', () async {
      final repository = buildRepository(fakeApiClient(buildCatalogue(3)), cache: cache);

      final result = await repository.getProduct(2);

      expect(result.data.title, 'Product 2');
      expect(result.isFromCache, isFalse);

      final offline = buildRepository(offlineClient(), cache: cache);
      final cached = await offline.getProduct(2);
      expect(cached.isFromCache, isTrue);
      expect(cached.data.title, 'Product 2');
    });

    test('surfaces NotFoundException without using the cache', () {
      final repository = buildRepository(fakeApiClient(buildCatalogue(1)), cache: cache);

      expect(repository.getProduct(99), throwsA(isA<NotFoundException>()));
    });
  });
}
