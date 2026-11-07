const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `9.991` -> `$9.99`
String formatPrice(double value) => '\$${value.toStringAsFixed(2)}';

/// Drops needless trailing zeros: `10.0` -> `10`, `12.48` -> `12.48`.
String formatNumber(num value, {int maxDecimals = 2}) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(maxDecimals)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// `12.48` -> `12.5%`
String formatPercent(double value) => '${formatNumber(value, maxDecimals: 1)}%';

/// `home-decoration` -> `Home Decoration`
String humanize(String raw) => raw
    .split(RegExp(r'[-_\s]+'))
    .where((word) => word.isNotEmpty)
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join(' ');

/// `2024-05-23T08:56:21Z` -> `May 23, 2024`
String formatDate(DateTime date) {
  final local = date.toLocal();
  return '${_months[local.month - 1]} ${local.day}, ${local.year}';
}
