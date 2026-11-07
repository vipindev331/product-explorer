import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:product_explorer/core/errors/app_exception.dart';
import 'package:product_explorer/data/datasources/product_remote_data_source.dart';

import '../../helpers/test_helpers.dart';

void main() {
  ProductRemoteDataSource buildSource(MockClient client, {Duration? timeout}) =>
      ProductRemoteDataSource(
        client: client,
        baseUrl: testBaseUrl,
        timeout: timeout ?? const Duration(seconds: 5),
      );

  test('requests the paged products endpoint', () async {
    late Uri requested;
    final source = buildSource(MockClient((request) async {
      requested = request.url;
      return http.Response('{}', 200);
    }));

    await source.fetchProducts(limit: 20, skip: 40);

    expect(requested.path, '/products');
    expect(requested.queryParameters, {'limit': '20', 'skip': '40'});
  });

  test('uses the search endpoint when a query is given', () async {
    late Uri requested;
    final source = buildSource(MockClient((request) async {
      requested = request.url;
      return http.Response('{}', 200);
    }));

    await source.fetchProducts(limit: 20, skip: 0, query: 'phone');

    expect(requested.path, '/products/search');
    expect(requested.queryParameters['q'], 'phone');
  });

  test('requests a single product by id', () async {
    late Uri requested;
    final source = buildSource(MockClient((request) async {
      requested = request.url;
      return http.Response('{}', 200);
    }));

    await source.fetchProduct(42);

    expect(requested.path, '/products/42');
  });

  test('maps a 404 to NotFoundException', () {
    final source = buildSource(MockClient((_) async => http.Response('', 404)));

    expect(source.fetchProduct(999), throwsA(isA<NotFoundException>()));
  });

  test('maps a 500 to ServerException', () {
    final source = buildSource(MockClient((_) async => http.Response('', 500)));

    expect(
      source.fetchProducts(limit: 20, skip: 0),
      throwsA(isA<ServerException>().having((e) => e.statusCode, 'statusCode', 500)),
    );
  });

  test('maps socket errors to NetworkException', () {
    final source = buildSource(offlineClient());

    expect(source.fetchProducts(limit: 20, skip: 0), throwsA(isA<NetworkException>()));
  });

  test('maps a timeout to NetworkException', () {
    final source = buildSource(
      MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 10),
    );

    expect(source.fetchProducts(limit: 20, skip: 0), throwsA(isA<NetworkException>()));
  });
}
