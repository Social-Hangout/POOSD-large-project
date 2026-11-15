import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/core/network/api_exception.dart';
import 'package:savory_app/features/authentication/data/sample_auth_repository.dart';

Matcher _status(int code) => throwsA(
  isA<ApiException>().having((e) => e.statusCode, 'statusCode', code),
);

void main() {
  // The credentials come from the test, as they come from --dart-define in the app.
  final repo = SampleAuthRepository(loginEmail: 'test', loginPassword: 'test');

  test('the configured credentials log in', () async {
    final session = await repo.login(email: 'test', password: 'test');
    expect(session.user.email, 'test');
    // The email is matched the way the API matches it: trimmed, any case.
    await repo.login(email: '  TEST ', password: 'test');
  });

  test('any other credentials get the API 401', () {
    expect(repo.login(email: 'test', password: 'Test'), _status(401));
    expect(repo.login(email: 'test', password: 'test '), _status(401));
    expect(repo.login(email: 'ana@test.com', password: 'test'), _status(401));
    expect(
      repo.login(email: 'ana@test.com', password: 'Passw0rd!'),
      _status(401),
    );
  });

  test('blank fields get the API 400', () {
    expect(repo.login(email: '', password: 'test'), _status(400));
    expect(repo.login(email: 'test', password: ''), _status(400));
  });

  test(
    'changing the name trims it and keeps the email, like PUT /users/me',
    () async {
      final user = await repo.updateName(firstName: ' Ana ', lastName: 'Diaz');
      expect(user.firstName, 'Ana');
      expect(user.lastName, 'Diaz');
      expect(user.email, 'test');
      expect(user.initials, 'AD');
    },
  );

  test('a blank or 51-character name gets the API 400', () {
    expect(repo.updateName(firstName: ' ', lastName: 'Diaz'), _status(400));
    expect(repo.updateName(firstName: 'Ana', lastName: 'x' * 51), _status(400));
  });

  test('with nothing configured, every login fails', () {
    final unconfigured = SampleAuthRepository(
      loginEmail: '',
      loginPassword: '',
    );
    expect(unconfigured.login(email: 'test', password: 'test'), _status(401));
    expect(unconfigured.login(email: '', password: ''), _status(400));
  });
}
