import 'package:flutter_test/flutter_test.dart';
import 'package:product_explorer/core/errors/app_exception.dart';
import 'package:product_explorer/data/models/product.dart';
import 'package:product_explorer/presentation/providers/product_detail_provider.dart';

import '../../helpers/test_helpers.dart';

void main() {
  final initial = Product.fromJson(buildProductJson(id: 1, title: 'Old title'));

  test('replaces the initial product with fresh API data', () async {
    final provider = ProductDetailProvider(
      repository: buildRepository(fakeApiClient([buildProductJson(id: 1, title: 'New title')])),
      initialProduct: initial,
    );

    expect(provider.product.title, 'Old title');
    await provider.refresh();

    expect(provider.product.title, 'New title');
    expect(provider.isShowingStaleData, isFalse);
    expect(provider.isRefreshing, isFalse);
  });

  test('keeps the initial product when offline', () async {
    final provider = ProductDetailProvider(
      repository: buildRepository(offlineClient()),
      initialProduct: initial,
    );

    await provider.refresh();

    expect(provider.product.title, 'Old title');
    expect(provider.refreshError, isA<NetworkException>());
    expect(provider.isOffline, isTrue);
  });
}
