import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// The real account routes (api/routes/auth.js). Request bodies match web/src/api/auth.ts.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<String> _postForMessage(String path, Map<String, dynamic> body) =>
      _call(() async {
        final res = await _dio.post<Map<String, dynamic>>(path, data: body);
        return res.data?['message'] as String? ?? '';
      });

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) => _postForMessage(ApiEndpoints.register, {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'password': password,
  });

  @override
  Future<String> resendVerification(String email) =>
      _postForMessage(ApiEndpoints.resendVerification, {'email': email});

  @override
  Future<String> forgotPassword(String email) =>
      _postForMessage(ApiEndpoints.forgotPassword, {'email': email});

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) => _call(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(res.data!);
  });
}
