import 'dart:convert';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product.dart';
import '../models/product_page.dart';

/// Data plus where it came from, so the UI can tell users they are offline.
class CachedResult<T> {
  const CachedResult(this.data, {this.isFromCache = false});

  final T data;
  final bool isFromCache;
}

/// Single source of truth for product data.
///
/// Strategy: network first. Every successful response is cached; when the
/// network or server fails, the last cached response for the same request is
/// returned instead. If nothing is cached, the original error is rethrown.
class ProductRepository {
  ProductRepository({
    required ProductRemoteDataSource remote,
    required ProductLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final ProductRemoteDataSource _remote;
  final ProductLocalDataSource _local;

  Future<CachedResult<ProductPage>> getProducts({
    int limit = ApiConstants.pageSize,
    int skip = 0,
    String query = '',
  }) {
    final normalized = query.trim();
    return _fetchWithCache(
      cacheKey: 'products|q=${normalized.toLowerCase()}|limit=$limit|skip=$skip',
      fetch: () => _remote.fetchProducts(limit: limit, skip: skip, query: normalized),
      parse: ProductPage.fromJson,
    );
  }

  Future<CachedResult<Product>> getProduct(int id) => _fetchWithCache(
        cacheKey: 'product|$id',
        fetch: () => _remote.fetchProduct(id),
        parse: Product.fromJson,
      );

  Future<CachedResult<T>> _fetchWithCache<T>({
    required String cacheKey,
    required Future<String> Function() fetch,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    try {
      final body = await fetch();
      final data = _decode(body, parse);
      await _writeCache(cacheKey, body);
      return CachedResult(data);
    } on AppException catch (error, stackTrace) {
      final canFallBack = error is NetworkException || error is ServerException;
      if (!canFallBack) rethrow;

      final cached = await _readCache(cacheKey);
      if (cached != null) {
        try {
          return CachedResult(_decode(cached, parse), isFromCache: true);
        } on DataParsingException {
          // Corrupt cache entry: surface the original error below.
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  T _decode<T>(String body, T Function(Map<String, dynamic>) parse) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object');
      }
      return parse(decoded);
    } catch (_) {
      throw const DataParsingException();
    }
  }

  Future<String?> _readCache(String key) async {
    try {
      return await _local.read(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, String body) async {
    try {
      await _local.write(key, body);
    } catch (_) {
      // Caching is best effort; a failed write must not fail the request.
    }
  }
}
