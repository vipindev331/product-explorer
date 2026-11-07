// Lenient JSON readers. The API occasionally sends ints where doubles are
// expected (e.g. `"price": 10`) and omits optional fields, so the models use
// these helpers instead of hard casts.

double asDouble(Object? value, {double fallback = 0}) =>
    asDoubleOrNull(value) ?? fallback;

double? asDoubleOrNull(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int asInt(Object? value, {int fallback = 0}) => asIntOrNull(value) ?? fallback;

int? asIntOrNull(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String asString(Object? value, {String fallback = ''}) =>
    asStringOrNull(value) ?? fallback;

/// Returns null for missing or blank strings.
String? asStringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

List<String> asStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .where((item) => item != null && item.toString().trim().isNotEmpty)
      .map((item) => item.toString())
      .toList(growable: false);
}

DateTime? asDateTimeOrNull(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

Map<String, dynamic>? asMapOrNull(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, val) => MapEntry('$key', val));
  return null;
}

List<Map<String, dynamic>> asMapList(Object? value) {
  if (value is! List) return const [];
  return value.map(asMapOrNull).whereType<Map<String, dynamic>>().toList();
}
