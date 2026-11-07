import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_explorer/core/errors/app_exception.dart';
import 'package:product_explorer/core/theme/app_theme.dart';
import 'package:product_explorer/data/models/product.dart';
import 'package:product_explorer/presentation/widgets/price_tag.dart';
import 'package:product_explorer/presentation/widgets/product_card.dart';
import 'package:product_explorer/presentation/widgets/rating_stars.dart';
import 'package:product_explorer/presentation/widgets/state_views.dart';
import 'package:product_explorer/presentation/widgets/stock_badge.dart';

import '../../helpers/test_helpers.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('RatingStars renders full, half and empty stars', (tester) async {
    await tester.pumpWidget(_wrap(const RatingStars(rating: 3.5)));

    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
  });

  testWidgets('PriceTag shows the original price only when discounted', (tester) async {
    await tester.pumpWidget(_wrap(const PriceTag(price: 8.99, originalPrice: 9.99)));
    expect(find.text('\$8.99'), findsOneWidget);
    expect(find.byKey(const Key('original_price')), findsOneWidget);

    await tester.pumpWidget(_wrap(const PriceTag(price: 8.99)));
    expect(find.byKey(const Key('original_price')), findsNothing);
  });

  testWidgets('StockBadge reflects stock levels', (tester) async {
    await tester.pumpWidget(_wrap(const StockBadge(stock: 0)));
    expect(find.text('Out of stock'), findsOneWidget);

    await tester.pumpWidget(_wrap(const StockBadge(stock: 4)));
    expect(find.text('Only 4 left'), findsOneWidget);

    await tester.pumpWidget(_wrap(const StockBadge(stock: 40)));
    expect(find.text('In stock'), findsOneWidget);
  });

  testWidgets('ProductCard shows image, title, price, category and rating', (tester) async {
    var tapped = false;
    final product = Product.fromJson(
      buildProductJson(title: 'Red Lipstick', category: 'beauty', price: 20, discountPercentage: 25, rating: 4.26),
    );

    await tester.pumpWidget(_wrap(SizedBox(
      width: 200,
      height: 300,
      child: ProductCard(product: product, onTap: () => tapped = true),
    )));

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Red Lipstick'), findsOneWidget);
    expect(find.text('Beauty'), findsOneWidget);
    expect(find.text('4.3'), findsOneWidget);
    expect(find.text('\$15.00'), findsOneWidget);
    expect(find.text('\$20.00'), findsOneWidget);
    expect(find.text('-25%'), findsOneWidget);

    await tester.tap(find.byType(ProductCard));
    expect(tapped, isTrue);
  });

  testWidgets('ErrorStateView shows the message and calls retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(_wrap(ErrorStateView(
      error: const NetworkException(),
      onRetry: () => retried = true,
    )));

    expect(find.text('No connection'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('retry_button')));
    expect(retried, isTrue);
  });
}
