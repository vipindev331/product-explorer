import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';

/// Talks to the DummyJSON API and returns raw JSON bodies.
///
/// Returning the raw body (instead of models) lets the repository cache the
/// exact response for offline use.
class ProductRemoteDataSource {
  ProductRemoteDataSource({
    required http.Client client,
    String baseUrl = ApiConstants.baseUrl,
    Duration timeout = ApiConstants.requestTimeout,
  })  : _client = client,
        _baseUrl = baseUrl,
        _timeout = timeout;

  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  Future<String> fetchProducts({
    required int limit,
    required int skip,
    String query = '',
  }) {
    final params = {'limit': '$limit', 'skip': '$skip'};
    final uri = query.isEmpty
        ? Uri.parse('$_baseUrl/products').replace(queryParameters: params)
        : Uri.parse('$_baseUrl/products/search')
            .replace(queryParameters: {'q': query, ...params});
    return _get(uri);
  }

  Future<String> fetchProduct(int id) => _get(Uri.parse('$_baseUrl/products/$id'));

  Future<String> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
      final status = response.statusCode;
      if (status >= 200 && status < 300) {
        return utf8.decode(response.bodyBytes, allowMalformed: true);
      }
      if (status == 404) throw const NotFoundException();
      throw ServerException(status);
    } on SocketException {
      throw const NetworkException();
    } on TlsException {
      throw const NetworkException();
    } on http.ClientException {
      throw const NetworkException();
    } on TimeoutException {
      throw const NetworkException(
        'The request took too long. Check your connection and try again.',
      );
    }
  }
}
