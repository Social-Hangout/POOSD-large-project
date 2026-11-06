import '../../../core/network/api_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// Offline stand-in (USE_SAMPLE_AUTH=true) that answers like api/routes/auth.js, so every
/// screen state can be demoed without a server:
/// - any email + any password of 8+ characters logs in as the sample user
/// - an email starting with "unverified" gets the 403 "verify your email" reply
/// - registering an email starting with "taken" gets the 409 reply
class SampleAuthRepository implements AuthRepository {
  static const _delay = Duration(milliseconds: 600);

  static const sampleUser = User(
    id: '6721f0c2a1b2c3d4e5f60718',
    firstName: 'Ana',
    lastName: 'Lopez',
    email: 'ana@test.com',
  );

  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_delay);
    if (email.startsWith('taken')) {
      throw const ApiException('Email already registered', statusCode: 409);
    }
  }

  @override
  Future<String> resendVerification(String email) async {
    await Future<void>.delayed(_delay);
    return 'If that account needs verifying, a new link was sent';
  }

  @override
  Future<String> forgotPassword(String email) async {
    await Future<void>.delayed(_delay);
    return 'If that email has an account, a reset link was sent';
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(_delay);
    if (password.length < 8) {
      throw const ApiException('Invalid credentials', statusCode: 401);
    }
    if (email.startsWith('unverified')) {
      throw const ApiException(
        'Please verify your email first',
        statusCode: 403,
      );
    }
    return const AuthSession(token: 'sample-token', user: sampleUser);
  }
}
