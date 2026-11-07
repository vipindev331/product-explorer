import 'package:flutter_test/flutter_test.dart';
import 'package:product_explorer/data/models/product.dart';
import 'package:product_explorer/data/models/product_page.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Product.fromJson', () {
    test('parses every field returned by the API', () {
      final product = Product.fromJson(buildProductJson());

      expect(product.id, 1);
      expect(product.title, 'Essence Mascara Lash Princess');
      expect(product.category, 'beauty');
      expect(product.price, 9.99);
      expect(product.discountPercentage, 10);
      expect(product.rating, 4.5);
      expect(product.stock, 25);
      expect(product.brand, 'Essence');
      expect(product.sku, 'RCH45Q1A');
      expect(product.weight, 2);
      expect(product.dimensions?.width, 23.17);
      expect(product.warrantyInformation, '1 month warranty');
      expect(product.shippingInformation, 'Ships in 1 month');
      expect(product.availabilityStatus, 'In Stock');
      expect(product.returnPolicy, '30 days return policy');
      expect(product.minimumOrderQuantity, 24);
      expect(product.tags, ['beauty', 'mascara']);
      expect(product.images, hasLength(1));
      expect(product.reviews.single.reviewerName, 'John Doe');
      expect(product.reviews.single.rating, 5);
      expect(product.meta?.barcode, '9164035109868');
      expect(product.meta?.createdAt, DateTime.utc(2024, 5, 23, 8, 56, 21, 618));
    });

    test('tolerates missing optional fields and int prices', () {
      final product = Product.fromJson({
        'id': 7,
        'title': 'Plain Mug',
        'price': 10,
        'thumbnail': 'https://example.com/mug.png',
      });

      expect(product.price, 10.0);
      expect(product.brand, isNull);
      expect(product.dimensions, isNull);
      expect(product.reviews, isEmpty);
      expect(product.tags, isEmpty);
      expect(product.galleryImages, ['https://example.com/mug.png']);
      expect(product.averageReviewRating, isNull);
    });

    test('computes the discounted price', () {
      final product = Product.fromJson(buildProductJson(price: 100, discountPercentage: 12.5));

      expect(product.hasDiscount, isTrue);
      expect(product.discountedPrice, closeTo(87.5, 0.0001));
    });

    test('treats a zero discount as no discount', () {
      final product = Product.fromJson(buildProductJson(price: 50, discountPercentage: 0));

      expect(product.hasDiscount, isFalse);
      expect(product.discountedPrice, 50);
    });
  });

  group('ProductPage.fromJson', () {
    test('parses products and paging info', () {
      final page = ProductPage.fromJson({
        'products': [buildProductJson(id: 1), buildProductJson(id: 2)],
        'total': 194,
        'skip': 20,
        'limit': 2,
      });

      expect(page.products.map((p) => p.id), [1, 2]);
      expect(page.total, 194);
      expect(page.skip, 20);
      expect(page.limit, 2);
    });

    test('throws when the products list is missing', () {
      expect(() => ProductPage.fromJson({'total': 0}), throwsFormatException);
    });
  });
}
