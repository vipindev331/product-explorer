import 'package:flutter_test/flutter_test.dart';
import 'package:product_explorer/core/utils/formatters.dart';

void main() {
  test('formatPrice always shows two decimals', () {
    expect(formatPrice(9.991), '\$9.99');
    expect(formatPrice(10), '\$10.00');
  });

  test('formatNumber drops trailing zeros', () {
    expect(formatNumber(10.0), '10');
    expect(formatNumber(12.48), '12.48');
    expect(formatNumber(12.50), '12.5');
  });

  test('formatPercent rounds to one decimal', () {
    expect(formatPercent(12.48), '12.5%');
    expect(formatPercent(10), '10%');
  });

  test('humanize turns API slugs into titles', () {
    expect(humanize('home-decoration'), 'Home Decoration');
    expect(humanize('mens-shirts'), 'Mens Shirts');
    expect(humanize('beauty'), 'Beauty');
  });

  test('formatDate uses a short month name', () {
    expect(formatDate(DateTime(2024, 5, 23)), 'May 23, 2024');
  });
}
