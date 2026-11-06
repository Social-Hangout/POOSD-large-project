import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';

/// Fires when a request that carried a token gets 401. The session controller logs out.
final unauthorizedEventsProvider = Provider<StreamController<void>>((ref) {
  final controller = StreamController<void>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

/// The one HTTP client, mirroring web/src/api/client.ts:
/// - the token goes on every request except /auth/... routes;
/// - a 401 on a request that carried the token clears the session and returns to login.
final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.requestTimeout,
      receiveTimeout: AppConfig.requestTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  );

  bool carriesToken(RequestOptions options) =>
      options.headers.containsKey('Authorization');

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokens.cached;
        if (token != null && !options.path.startsWith('/auth/')) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401 &&
            carriesToken(error.requestOptions)) {
          ref.read(unauthorizedEventsProvider).add(null);
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});
