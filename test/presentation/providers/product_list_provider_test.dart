import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:product_explorer/core/errors/app_exception.dart';
import 'package:product_explorer/presentation/providers/product_list_provider.dart';

import '../../helpers/test_helpers.dart';

void main() {
  test('starts in the initial state', () {
    final provider = ProductListProvider(repository: buildRepository(fakeApiClient([])));

    expect(provider.status, ProductListStatus.initial);
    expect(provider.products, isEmpty);
  });

  test('goes through loading to loaded', () async {
    final provider = ProductListProvider(
      repository: buildRepository(fakeApiClient(buildCatalogue(3))),
    );
    final statuses = <ProductListStatus>[];
    provider.addListener(() => statuses.add(provider.status));

    await provider.loadInitial();

    expect(statuses, [ProductListStatus.loading, ProductListStatus.loaded]);
    expect(provider.products, hasLength(3));
    expect(provider.hasMore, isFalse);
    expect(provider.isOffline, isFalse);
  });

  test('reports an empty catalogue', () async {
    final provider = ProductListProvider(repository: buildRepository(fakeApiClient([])));

    await provider.loadInitial();

    expect(provider.status, ProductListStatus.empty);
  });

  test('reports errors and recovers on retry', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) return http.Response('down', 500);
      return http.Response(buildPageBody(buildCatalogue(2)), 200);
    });
    final provider = ProductListProvider(repository: buildRepository(client));

    await provider.loadInitial();
    expect(provider.status, ProductListStatus.error);
    expect(provider.error, isA<ServerException>());

    await provider.retry();
    expect(provider.status, ProductListStatus.loaded);
    expect(provider.products, hasLength(2));
    expect(provider.error, isNull);
  });

  test('paginates until every product is loaded', () async {
    final requests = <Uri>[];
    final provider = ProductListProvider(
      repository: buildRepository(fakeApiClient(buildCatalogue(25), requests: requests)),
      pageSize: 10,
    );

    await provider.loadInitial();
    expect(provider.products, hasLength(10));
    expect(provider.hasMore, isTrue);

    await provider.loadMore();
    expect(provider.products, hasLength(20));

    await provider.loadMore();
    expect(provider.products, hasLength(25));
    expect(provider.hasMore, isFalse);

    await provider.loadMore();
    expect(requests, hasLength(3), reason: 'no request once everything is loaded');
    expect(requests.map((uri) => uri.queryParameters['skip']), ['0', '10', '20']);
  });

  test('keeps loaded products when a later page fails', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 2) return http.Response('down', 500);
      return http.Response(buildPageBody(buildCatalogue(10), total: 30), 200);
    });
    final provider = ProductListProvider(repository: buildRepository(client), pageSize: 10);

    await provider.loadInitial();
    await provider.loadMore();

    expect(provider.status, ProductListStatus.loaded);
    expect(provider.products, hasLength(10));
    expect(provider.loadMoreError, isA<ServerException>());
    expect(provider.canLoadMore, isFalse, reason: 'waits for an explicit retry');
  });

  test('searches with the query and clears back to all products', () async {
    final catalogue = [
      buildProductJson(id: 1, title: 'iPhone 9'),
      buildProductJson(id: 2, title: 'Red Lipstick'),
      buildProductJson(id: 3, title: 'iPhone X'),
    ];
    final provider = ProductListProvider(repository: buildRepository(fakeApiClient(catalogue)));
    await provider.loadInitial();

    await provider.search('  iphone ');
    expect(provider.query, 'iphone');
    expect(provider.isSearching, isTrue);
    expect(provider.products.map((p) => p.title), ['iPhone 9', 'iPhone X']);

    await provider.search('zzz');
    expect(provider.status, ProductListStatus.empty);

    await provider.search('');
    expect(provider.products, hasLength(3));
  });

  test('flags cached data as offline', () async {
    final cache = InMemoryProductCache();
    await buildRepository(fakeApiClient(buildCatalogue(2)), cache: cache).getProducts();

    final provider = ProductListProvider(repository: buildRepository(offlineClient(), cache: cache));
    await provider.loadInitial();

    expect(provider.status, ProductListStatus.loaded);
    expect(provider.isOffline, isTrue);
  });

  test('refresh keeps current products if it fails', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) return http.Response(buildPageBody(buildCatalogue(2)), 200);
      return http.Response('down', 500);
    });
    // A fresh cache per call would hide the failure; use one without fallback data.
    final provider = ProductListProvider(repository: buildRepository(client, cache: _NoopCache()));
    await provider.loadInitial();

    final refreshed = await provider.refresh();

    expect(refreshed, isFalse);
    expect(provider.status, ProductListStatus.loaded);
    expect(provider.products, hasLength(2));
  });
}

class _NoopCache extends InMemoryProductCache {
  @override
  Future<void> write(String key, String value) async {}
}
