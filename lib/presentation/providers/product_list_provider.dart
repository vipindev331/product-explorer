import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

enum ProductListStatus { initial, loading, loaded, empty, error }

/// State for the product listing: first load, pagination, search and refresh.
class ProductListProvider extends ChangeNotifier {
  ProductListProvider({
    required ProductRepository repository,
    this.pageSize = ApiConstants.pageSize,
  }) : _repository = repository;

  final ProductRepository _repository;
  final int pageSize;

  ProductListStatus _status = ProductListStatus.initial;
  List<Product> _products = const [];
  int _total = 0;
  String _query = '';
  AppException? _error;
  AppException? _loadMoreError;
  bool _isLoadingMore = false;
  bool _reachedEnd = false;
  bool _isOffline = false;
  bool _disposed = false;

  /// Incremented for every new list request so stale responses are ignored
  /// (e.g. a slow search result arriving after the user typed something else).
  int _generation = 0;

  ProductListStatus get status => _status;
  List<Product> get products => _products;
  int get total => _total;
  String get query => _query;
  bool get isSearching => _query.isNotEmpty;
  AppException? get error => _error;
  AppException? get loadMoreError => _loadMoreError;
  bool get isLoadingMore => _isLoadingMore;

  /// True when the visible data came from the offline cache.
  bool get isOffline => _isOffline;

  bool get hasMore => !_reachedEnd && _products.length < _total;

  bool get canLoadMore =>
      _status == ProductListStatus.loaded &&
      hasMore &&
      !_isLoadingMore &&
      _loadMoreError == null;

  Future<void> loadInitial() async {
    await _loadFirstPage(showLoading: true);
  }

  Future<void> retry() async {
    await _loadFirstPage(showLoading: true);
  }

  /// Pull-to-refresh. Keeps the current list visible while loading and
  /// returns false if the refresh failed while products were on screen.
  Future<bool> refresh() {
    final hasContent = _status == ProductListStatus.loaded;
    return _loadFirstPage(showLoading: !hasContent, keepDataOnError: hasContent);
  }

  Future<void> search(String query) async {
    final normalized = query.trim();
    if (normalized == _query && _status != ProductListStatus.error) return;
    _query = normalized;
    await _loadFirstPage(showLoading: true);
  }

  Future<void> loadMore() async {
    if (!canLoadMore) return;
    final generation = _generation;
    _isLoadingMore = true;
    _loadMoreError = null;
    _notify();

    try {
      final result = await _repository.getProducts(
        limit: pageSize,
        skip: _products.length,
        query: _query,
      );
      if (generation != _generation) return;

      final seenIds = _products.map((product) => product.id).toSet();
      final newProducts =
          result.data.products.where((product) => seenIds.add(product.id)).toList();
      _products = List.unmodifiable([..._products, ...newProducts]);
      _total = result.data.total;
      _reachedEnd = newProducts.isEmpty;
      if (result.isFromCache) _isOffline = true;
    } on AppException catch (error) {
      if (generation != _generation) return;
      _loadMoreError = error;
    }

    _isLoadingMore = false;
    _notify();
  }

  Future<bool> _loadFirstPage({
    required bool showLoading,
    bool keepDataOnError = false,
  }) async {
    final generation = ++_generation;
    _isLoadingMore = false;
    _loadMoreError = null;
    if (showLoading) {
      _status = ProductListStatus.loading;
      _error = null;
      _notify();
    }

    try {
      final result = await _repository.getProducts(limit: pageSize, query: _query);
      if (generation != _generation) return false;

      final page = result.data;
      _products = List.unmodifiable(page.products);
      _total = page.total;
      _reachedEnd = page.products.isEmpty;
      _isOffline = result.isFromCache;
      _error = null;
      _status = _products.isEmpty ? ProductListStatus.empty : ProductListStatus.loaded;
      _notify();
      return true;
    } on AppException catch (error) {
      if (generation != _generation) return false;
      if (!keepDataOnError) {
        _error = error;
        _status = ProductListStatus.error;
        _products = const [];
        _total = 0;
        _isOffline = false;
      }
      _notify();
      return false;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
