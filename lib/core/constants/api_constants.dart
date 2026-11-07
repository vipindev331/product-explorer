/// Configuration for the DummyJSON Products API.
abstract final class ApiConstants {
  static const String baseUrl = 'https://dummyjson.com';
  static const Duration requestTimeout = Duration(seconds: 15);
  static const int pageSize = 20;
}
