import '../../core/utils/json_parsing.dart';
import 'product.dart';

/// One page of results from `GET /products` or `GET /products/search`.
class ProductPage {
  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductPage.fromJson(Map<String, dynamic> json) {
    if (json['products'] is! List) {
      throw const FormatException('Response has no "products" list');
    }
    final products = asMapList(json['products']).map(Product.fromJson).toList();
    return ProductPage(
      products: products,
      total: asInt(json['total'], fallback: products.length),
      skip: asInt(json['skip']),
      limit: asInt(json['limit'], fallback: products.length),
    );
  }

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;
}
