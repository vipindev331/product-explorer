import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

/// Shows the product passed from the list immediately, then refreshes it from
/// `GET /products/{id}`. If that fails, the screen keeps the data it has.
class ProductDetailProvider extends ChangeNotifier {
  ProductDetailProvider({
    required ProductRepository repository,
    required Product initialProduct,
  })  : _repository = repository,
        _product = initialProduct;

  final ProductRepository _repository;
  Product _product;
  bool _isRefreshing = false;
  bool _isFromCache = false;
  AppException? _refreshError;
  bool _disposed = false;

  Product get product => _product;
  bool get isRefreshing => _isRefreshing;
  bool get isFromCache => _isFromCache;
  AppException? get refreshError => _refreshError;

  bool get isOffline => _isFromCache || _refreshError is NetworkException;

  /// True when the details shown may be out of date.
  bool get isShowingStaleData => _isFromCache || _refreshError != null;

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    _refreshError = null;
    _notify();

    try {
      final result = await _repository.getProduct(_product.id);
      _product = result.data;
      _isFromCache = result.isFromCache;
    } on AppException catch (error) {
      _refreshError = error;
    } finally {
      _isRefreshing = false;
      _notify();
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
