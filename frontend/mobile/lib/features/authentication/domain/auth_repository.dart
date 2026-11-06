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
  /// web app's /reset-password page, where the new password is chosen.
  Future<String> forgotPassword(String email);

  /// POST /auth/login. 401 = wrong email or password, 403 = email not verified yet.
  Future<AuthSession> login({required String email, required String password});
}
