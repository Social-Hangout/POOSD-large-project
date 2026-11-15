import 'user.dart';

/// The account routes the app calls, one method per route, like web/src/api/auth.ts.
/// Every method throws ApiException carrying the API's `{ error }` message.
abstract class AuthRepository {
  /// POST /auth/register. Creates an unverified account and emails a verification link.
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  /// POST /auth/resend-verification. Returns the API's message (the same whether or not
  /// the account exists).
  Future<String> resendVerification(String email);

  /// POST /auth/forgot-password. Returns the API's message. The emailed link opens the
  /// web app's /reset-password page; the app's Change password screen accepts the same
  /// link (see [resetPassword]).
  Future<String> forgotPassword(String email);

  /// POST /auth/reset-password with the token from the emailed link and the new password
  /// (the API reads it from `newPassword`, as web/src/api/auth.ts sends it). Returns the
  /// API's message. 400 "Invalid or expired link" (bad, used or hour-old token) or
  /// "Password must be at least 8 characters".
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  });

  /// POST /auth/login. 401 = wrong email or password, 403 = email not verified yet.
  Future<AuthSession> login({required String email, required String password});

  /// PUT /users/me. Changes the logged-in user's name and returns the updated user.
  /// Names are trimmed and 1 to 50 characters; the email can't change. 400 = bad name,
  /// 401 = session expired.
  Future<User> updateName({
    required String firstName,
    required String lastName,
  });
}
