/// Errors the UI knows how to present. Lower layers translate low-level
/// failures (sockets, HTTP codes, malformed JSON) into one of these.
sealed class AppException implements Exception {
  const AppException(this.message);

  /// A user-facing explanation of what went wrong and what to do next.
  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

class NetworkException extends AppException {
  const NetworkException([
    super.message =
        'Can’t reach the product server. Check your internet connection and try again.',
  ]);
}

class ServerException extends AppException {
  ServerException(this.statusCode)
      : super(
          'The product server returned an error ($statusCode). Try again in a moment.',
        );

  final int statusCode;
}

class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'This product is no longer available.',
  ]);
}

class DataParsingException extends AppException {
  const DataParsingException([
    super.message = 'Product data arrived in an unexpected format. Try again later.',
  ]);
}
