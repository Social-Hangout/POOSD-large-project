import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/auth_providers.dart';
import '../../domain/user.dart';

/// Who is logged in, like the web's AuthContext. `AsyncData(null)` means logged out.
///
/// On launch it restores the saved token and user without a network call, as the web app
/// does from localStorage. An expired token is caught by the first request that returns 401.
class SessionController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final sub = ref
        .read(unauthorizedEventsProvider)
        .stream
        .listen((_) => _handleUnauthorized());
    ref.onDispose(sub.cancel);

    final saved = await ref.read(tokenStorageProvider).readSession();
    return saved?.user;
  }

  /// POST /auth/login, then save the session. Throws ApiException (401, 403, 400, ...).
  Future<void> login({required String email, required String password}) async {
    final session = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    await ref.read(tokenStorageProvider).save(session.token, session.user);
    state = AsyncData(session.user);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }

  void _handleUnauthorized() {
    if (state.valueOrNull == null) return;
    unawaited(logout());
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, User?>(SessionController.new);
