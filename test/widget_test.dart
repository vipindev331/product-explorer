import 'package:flutter_test/flutter_test.dart';
import 'package:product_explorer/app.dart';
import 'package:product_explorer/presentation/widgets/product_card.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgets('app starts and lists products from the (fake) API', (tester) async {
    await tester.pumpWidget(
      ProductExplorerApp(repository: buildRepository(fakeApiClient(buildCatalogue(4)))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product Explorer'), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(4));
  });
}
