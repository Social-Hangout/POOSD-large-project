import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// Offline stand-in (USE_SAMPLE_AUTH=true) that answers like api/routes/auth.js, so the
/// screens can be demoed without a server:
/// - login succeeds only with the one email and password given at build time
///   (SAMPLE_LOGIN_EMAIL / SAMPLE_LOGIN_PASSWORD, see AppConfig); anything else gets the
///   API's 401 "Invalid credentials", and blank fields get its 400
/// - registering an email starting with "taken" gets the 409 reply
/// - changing the name follows PUT /api/users/me: trimmed, 1 to 50 characters, else 400
///
/// Nothing here hashes or stores a password: that is the API's job (bcrypt, server side).
class SampleAuthRepository implements AuthRepository {
  SampleAuthRepository({String? loginEmail, String? loginPassword})
    : _loginEmail = loginEmail ?? AppConfig.sampleLoginEmail,
      _loginPassword = loginPassword ?? AppConfig.sampleLoginPassword;

  final String _loginEmail;
  final String _loginPassword;

  static const _delay = Duration(milliseconds: 600);

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
    // Same checks and order as POST /api/auth/login.
    if (email.trim().isEmpty || password.isEmpty) {
      throw const ApiException(
        'Email and password are required',
        statusCode: 400,
      );
    }
    final configured = _loginEmail.isNotEmpty && _loginPassword.isNotEmpty;
    final matches =
        configured &&
        email.trim().toLowerCase() == _loginEmail.trim().toLowerCase() &&
        password == _loginPassword;
    if (!matches) {
      throw const ApiException('Invalid credentials', statusCode: 401);
    }
    return AuthSession(
      token: 'sample-token',
      user: _user(firstName: 'Test', lastName: 'User'),
    );
  }

  @override
  Future<User> updateName({
    required String firstName,
    required String lastName,
  }) async {
    await Future<void>.delayed(_delay);
    bool valid(String name) =>
        name.trim().isNotEmpty && name.trim().length <= 50;
    if (!valid(firstName) || !valid(lastName)) {
      throw const ApiException(
        'First and last name must be 1 to 50 characters',
        statusCode: 400,
      );
    }
    return _user(firstName: firstName.trim(), lastName: lastName.trim());
  }

  /// The one sample user; only the name can change, as on the API.
  User _user({required String firstName, required String lastName}) => User(
    id: '6721f0c2a1b2c3d4e5f60718',
    firstName: firstName,
    lastName: lastName,
    email: _loginEmail.trim().toLowerCase(),
  );
}
