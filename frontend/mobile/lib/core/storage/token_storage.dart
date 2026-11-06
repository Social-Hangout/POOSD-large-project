import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/authentication/domain/user.dart';

/// Keeps the session between launches, like the web app's localStorage "token" and "user"
/// (web/src/context/AuthContext.tsx), but in the platform keychain/keystore.
/// The JWT lasts 24 hours and there is no refresh token: a 401 ends the session.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'token';
  static const _userKey = 'user';
  final FlutterSecureStorage _storage;
  String? _cached;

  /// Synchronous read for the request interceptor; valid after [readSession] or [save].
  String? get cached => _cached;

  /// The saved token and user, or null. A user that can't be read counts as no session,
  /// as the web's readUser() does.
  Future<({String token, User user})?> readSession() async {
    final token = await _storage.read(key: _tokenKey);
    final userJson = await _storage.read(key: _userKey);
    if (token == null || userJson == null) return null;
    try {
      final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      _cached = token;
      return (token: token, user: user);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> save(String token, User user) async {
    _cached = token;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
