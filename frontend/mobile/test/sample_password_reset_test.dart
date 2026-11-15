// Offline reset-password (USE_SAMPLE_AUTH=true) answers like POST /api/auth/reset-password.
import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/core/network/api_exception.dart';
import 'package:savory_app/features/authentication/data/sample_auth_repository.dart';

Matcher _error(String message) => throwsA(
  isA<ApiException>()
      .having((e) => e.statusCode, 'statusCode', 400)
      .having((e) => e.message, 'message', message),
);

void main() {
  final token = 'f0' * 32;

  test('a malformed token is an invalid link, checked before the password', () {
    final repo = SampleAuthRepository(loginEmail: 'test', loginPassword: 'test');
    expect(
      repo.resetPassword(token: 'abc', newPassword: 'x'),
      _error('Invalid or expired link'),
    );
  });

  test('a password under 8 characters is refused', () {
    final repo = SampleAuthRepository(loginEmail: 'test', loginPassword: 'test');
    expect(
      repo.resetPassword(token: token, newPassword: 'short'),
      _error('Password must be at least 8 characters'),
    );
  });

  test('success returns the API message, and the new password logs in', () async {
    final repo = SampleAuthRepository(loginEmail: 'test', loginPassword: 'test');
    expect(
      await repo.resetPassword(token: token, newPassword: 'Fresh#basil1'),
      'Password updated. You can log in now.',
    );
    await expectLater(
      repo.login(email: 'test', password: 'test'),
      throwsA(isA<ApiException>()),
    );
    final session = await repo.login(email: 'test', password: 'Fresh#basil1');
    expect(session.user.email, 'test');
  });
}
