import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_explorer/core/theme/app_theme.dart';
import 'package:product_explorer/data/models/product.dart';
import 'package:product_explorer/data/repositories/product_repository.dart';
import 'package:product_explorer/presentation/screens/product_detail_screen.dart';
import 'package:product_explorer/presentation/widgets/product_image_gallery.dart';
import 'package:provider/provider.dart';

import '../../helpers/test_helpers.dart';

Future<void> _pumpDetails(
  WidgetTester tester, {
  required Product product,
  required ProductRepository repository,
}) async {
  await tester.pumpWidget(
    Provider<ProductRepository>.value(
      value: repository,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: ProductDetailScreen(product: product),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final json = buildProductJson(
    images: const [
      'https://cdn.dummyjson.com/products/images/beauty/1.png',
      'https://cdn.dummyjson.com/products/images/beauty/2.png',
      'https://cdn.dummyjson.com/products/images/beauty/3.png',
    ],
  );

  testWidgets('shows every product detail from the API', (tester) async {
    final product = Product.fromJson(json);
    await _pumpDetails(
      tester,
      product: product,
      repository: buildRepository(fakeApiClient([json])),
    );

    Finder text(String value) => find.text(value, skipOffstage: false);

    // Gallery
    expect(find.byType(ProductImageGallery), findsOneWidget);
    expect(text('1/3'), findsOneWidget);
    // Title, brand, category
    expect(text('Essence Mascara Lash Princess'), findsOneWidget);
    expect(text('Essence'), findsWidgets);
    expect(text('Beauty'), findsWidgets);
    // Price and discount
    expect(text('\$8.99'), findsOneWidget);
    expect(text('\$9.99'), findsOneWidget);
    expect(text('Save 10%'), findsOneWidget);
    // Rating and stock
    expect(text('4.50'), findsOneWidget);
    expect(text('In stock'), findsOneWidget);
    expect(text('25 units'), findsOneWidget);
    // Description and other information
    expect(text('A popular mascara known for its volumizing effects.'), findsOneWidget);
    expect(text('RCH45Q1A'), findsOneWidget);
    expect(text('Ships in 1 month'), findsOneWidget);
    expect(text('1 month warranty'), findsOneWidget);
    expect(text('30 days return policy'), findsOneWidget);
    expect(text('John Doe'), findsOneWidget);
    expect(text('Very happy with my purchase!'), findsOneWidget);
    expect(text('9164035109868'), findsOneWidget);

    expect(find.byKey(const Key('offline_note'), skipOffstage: false), findsNothing);
  });

  testWidgets('still shows the product and an offline note without internet', (tester) async {
    final product = Product.fromJson(json);
    await _pumpDetails(tester, product: product, repository: buildRepository(offlineClient()));

    expect(find.text('Essence Mascara Lash Princess', skipOffstage: false), findsOneWidget);
    expect(find.byKey(const Key('offline_note'), skipOffstage: false), findsOneWidget);
  });
}
