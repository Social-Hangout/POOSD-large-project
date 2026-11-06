import 'package:dio/dio.dart';

/// Same idea as the web's ApiError (web/src/api/client.ts): the API's `{ error }` message
/// plus the status code. [message] can be shown to the user as is.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;

  /// HTTP status, or null when no response arrived (offline, timeout).
  final int? statusCode;

  /// web/src/api/client.ts fallback when the body has no `error`.
  static const genericMessage = 'Something went wrong. Please try again.';
  static const offlineMessage =
      "Couldn't reach the server. Check your connection and try again.";

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response == null) return const ApiException(offlineMessage);
    final data = response.data;
    final message = data is Map && data['error'] is String
        ? data['error'] as String
        : genericMessage;
    return ApiException(message, statusCode: response.statusCode);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
