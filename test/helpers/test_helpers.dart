import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:product_explorer/data/datasources/product_local_data_source.dart';
import 'package:product_explorer/data/datasources/product_remote_data_source.dart';
import 'package:product_explorer/data/repositories/product_repository.dart';

/// Tests never hit the real API: every client below is a [MockClient].
const testBaseUrl = 'https://dummyjson.test';

Map<String, dynamic> buildProductJson({
  int id = 1,
  String title = 'Essence Mascara Lash Princess',
  String description = 'A popular mascara known for its volumizing effects.',
  String category = 'beauty',
  num price = 9.99,
  num discountPercentage = 10,
  num rating = 4.5,
  int stock = 25,
  String? brand = 'Essence',
  List<String>? images,
}) =>
    {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'stock': stock,
      'tags': ['beauty', 'mascara'],
      if (brand != null) 'brand': brand,
      'sku': 'RCH45Q1A',
      'weight': 2,
      'dimensions': {'width': 23.17, 'height': 14.43, 'depth': 28.01},
      'warrantyInformation': '1 month warranty',
      'shippingInformation': 'Ships in 1 month',
      'availabilityStatus': 'In Stock',
      'reviews': [
        {
          'rating': 5,
          'comment': 'Very happy with my purchase!',
          'date': '2024-05-23T08:56:21.618Z',
          'reviewerName': 'John Doe',
          'reviewerEmail': 'john.doe@x.dummyjson.com',
        },
      ],
      'returnPolicy': '30 days return policy',
      'minimumOrderQuantity': 24,
      'meta': {
        'createdAt': '2024-05-23T08:56:21.618Z',
        'updatedAt': '2024-05-23T08:56:21.618Z',
        'barcode': '9164035109868',
        'qrCode': 'https://assets.dummyjson.com/public/qr-code.png',
      },
      'images': images ?? ['https://cdn.dummyjson.com/products/images/beauty/1.png'],
      'thumbnail': 'https://cdn.dummyjson.com/products/images/beauty/thumbnail.png',
    };

List<Map<String, dynamic>> buildCatalogue(int count) => List.generate(
      count,
      (index) => buildProductJson(id: index + 1, title: 'Product ${index + 1}'),
    );

String buildPageBody(
  List<Map<String, dynamic>> products, {
  int? total,
  int skip = 0,
  int limit = 20,
}) =>
    jsonEncode({
      'products': products,
      'total': total ?? products.length,
      'skip': skip,
      'limit': limit,
    });

/// Fake of the DummyJSON API backed by [catalogue]. Supports `/products`,
/// `/products/search?q=` and `/products/{id}` with `limit`/`skip` paging.
MockClient fakeApiClient(List<Map<String, dynamic>> catalogue, {List<Uri>? requests}) {
  return MockClient((request) async {
    requests?.add(request.url);
    final segments = request.url.pathSegments;
    final params = request.url.queryParameters;

    if (segments.length == 2 && segments[1] == 'search') {
      final query = (params['q'] ?? '').toLowerCase();
      final matches = catalogue
          .where((product) => (product['title'] as String).toLowerCase().contains(query))
          .toList();
      return _pageResponse(matches, params);
    }

    if (segments.length == 2) {
      final id = int.tryParse(segments[1]);
      final match = catalogue.where((product) => product['id'] == id);
      if (match.isEmpty) return http.Response('{"message":"not found"}', 404);
      return http.Response(jsonEncode(match.first), 200);
    }

    return _pageResponse(catalogue, params);
  });
}

http.Response _pageResponse(List<Map<String, dynamic>> items, Map<String, String> params) {
  final skip = int.tryParse(params['skip'] ?? '') ?? 0;
  final limit = int.tryParse(params['limit'] ?? '') ?? 30;
  final slice = items.skip(skip).take(limit).toList();
  return http.Response(
    buildPageBody(slice, total: items.length, skip: skip, limit: limit),
    200,
  );
}

/// Simulates having no internet connection.
MockClient offlineClient() =>
    MockClient((_) async => throw const SocketException('Failed host lookup'));

class InMemoryProductCache implements ProductLocalDataSource {
  final Map<String, String> store = {};

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> write(String key, String value) async => store[key] = value;

  @override
  Future<void> clear() async => store.clear();
}

ProductRepository buildRepository(http.Client client, {ProductLocalDataSource? cache}) =>
    ProductRepository(
      remote: ProductRemoteDataSource(client: client, baseUrl: testBaseUrl),
      local: cache ?? InMemoryProductCache(),
    );
