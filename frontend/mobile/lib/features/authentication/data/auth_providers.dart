import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_repository.dart';
import 'api_auth_repository.dart';
import 'sample_auth_repository.dart';

/// The only place that decides between sample and live auth.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useSampleAuth) return SampleAuthRepository();
  return ApiAuthRepository(ref.watch(dioProvider));
});
