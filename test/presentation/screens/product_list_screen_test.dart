import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:product_explorer/app.dart';
import 'package:product_explorer/presentation/screens/product_detail_screen.dart';
import 'package:product_explorer/presentation/widgets/product_card.dart';

import '../../helpers/test_helpers.dart';

void main() {
  testWidgets('shows a loading skeleton, then the product grid', (tester) async {
    final response = Completer<http.Response>();
    final repository = buildRepository(MockClient((_) => response.future));

    await tester.pumpWidget(ProductExplorerApp(repository: repository));
    await tester.pump();
    expect(find.byKey(const Key('loading_view')), findsOneWidget);

    response.complete(http.Response(
      buildPageBody([
        buildProductJson(id: 1, title: 'Red Lipstick'),
        buildProductJson(id: 2, title: 'Blue Mascara'),
      ]),
      200,
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loading_view')), findsNothing);
    expect(find.byType(ProductCard), findsNWidgets(2));
    expect(find.text('Red Lipstick'), findsOneWidget);
    expect(find.text('Blue Mascara'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no products', (tester) async {
    await tester.pumpWidget(ProductExplorerApp(repository: buildRepository(fakeApiClient([]))));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty_view')), findsOneWidget);
    expect(find.text('No products yet'), findsOneWidget);
  });

  testWidgets('shows the error state and recovers with retry', (tester) async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) return http.Response('down', 500);
      return http.Response(buildPageBody(buildCatalogue(2)), 200);
    });

    await tester.pumpWidget(ProductExplorerApp(repository: buildRepository(client)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error_view')), findsOneWidget);

    await tester.tap(find.byKey(const Key('retry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('error_view')), findsNothing);
    expect(find.byType(ProductCard), findsNWidgets(2));
  });

  testWidgets('shows an offline banner when products come from the cache', (tester) async {
    final cache = InMemoryProductCache();
    await tester.runAsync(
      () => buildRepository(fakeApiClient(buildCatalogue(2)), cache: cache).getProducts(),
    );

    await tester.pumpWidget(
      ProductExplorerApp(repository: buildRepository(offlineClient(), cache: cache)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('offline_banner')), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(2));
  });

  testWidgets('filters products with search', (tester) async {
    final catalogue = [
      buildProductJson(id: 1, title: 'Red Lipstick'),
      buildProductJson(id: 2, title: 'Blue Mascara'),
    ];
    await tester.pumpWidget(ProductExplorerApp(repository: buildRepository(fakeApiClient(catalogue))));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('search_field')), 'mascara');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.byType(ProductCard), findsOneWidget);
    expect(find.text('Blue Mascara'), findsOneWidget);
    expect(find.text('Red Lipstick'), findsNothing);
  });

  testWidgets('search field loses focus once the search has completed', (tester) async {
    final catalogue = [
      buildProductJson(id: 1, title: 'Red Lipstick'),
      buildProductJson(id: 2, title: 'Blue Mascara'),
    ];
    await tester.pumpWidget(ProductExplorerApp(repository: buildRepository(fakeApiClient(catalogue))));
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('search_field'));
    await tester.showKeyboard(field);
    await tester.enterText(field, 'mascara');
    await tester.pump();
    final editableFinder = find.descendant(of: field, matching: find.byType(EditableText));
    expect(tester.widget<EditableText>(editableFinder).focusNode.hasFocus, isTrue);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Blue Mascara'), findsOneWidget);
    expect(tester.widget<EditableText>(editableFinder).focusNode.hasFocus, isFalse);
  });

  testWidgets('tapping outside the search field removes focus', (tester) async {
    final catalogue = [buildProductJson(id: 1, title: 'Red Lipstick')];
    await tester.pumpWidget(ProductExplorerApp(repository: buildRepository(fakeApiClient(catalogue))));
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('search_field'));
    final editableFinder = find.descendant(of: field, matching: find.byType(EditableText));
    await tester.tap(field);
    await tester.pump();
    expect(tester.widget<EditableText>(editableFinder).focusNode.hasFocus, isTrue);

    await tester.tapAt(const Offset(200, 500));
    await tester.pump();
    expect(tester.widget<EditableText>(editableFinder).focusNode.hasFocus, isFalse);
  });

  testWidgets('opens the details screen when a product is tapped', (tester) async {
    final catalogue = [
      buildProductJson(id: 1, title: 'Red Lipstick', description: 'Long-lasting matte colour.'),
    ];
    await tester.pumpWidget(ProductExplorerApp(repository: buildRepository(fakeApiClient(catalogue))));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('product_card_1')));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsOneWidget);
    expect(find.text('Long-lasting matte colour.', skipOffstage: false), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailScreen), findsNothing);
  });
}
