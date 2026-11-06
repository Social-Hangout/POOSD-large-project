import 'package:flutter_test/flutter_test.dart';
import 'package:savory_app/features/authentication/presentation/controllers/auth_form_validators.dart';

// Same rules and messages as web/src/pages/AuthPage.tsx (RegisterForm).
void main() {
  test('names only need to be non-blank', () {
    expect(AuthFormValidators.firstName('  '), 'Enter your first name.');
    expect(AuthFormValidators.lastName(''), 'Enter your last name.');
    expect(AuthFormValidators.firstName('Ana'), isNull);
  });

  test('email uses the web regex, on the value as typed', () {
    expect(AuthFormValidators.email('kai@email.com'), isNull);
    expect(
      AuthFormValidators.email('kai@email'),
      'Enter a valid email, e.g. kai@email.com.',
    );
    expect(AuthFormValidators.email('kai@email.com '), isNotNull);
  });

  test('password needs 8+ characters, a number and a symbol', () {
    const message = 'Use at least 8 characters, a number and a symbol.';
    expect(AuthFormValidators.password('password'), message);
    expect(AuthFormValidators.password('password1'), message);
    expect(AuthFormValidators.password('pass1!'), message);
    expect(AuthFormValidators.password('password1!'), isNull);
  });

  test('confirm must be filled and match', () {
    expect(
      AuthFormValidators.confirmPassword('', ''),
      "Passwords don't match.",
    );
    expect(
      AuthFormValidators.confirmPassword('a1!aaaaa', 'b1!bbbbb'),
      "Passwords don't match.",
    );
    expect(AuthFormValidators.confirmPassword('a1!aaaaa', 'a1!aaaaa'), isNull);
  });

  test('strength counts length, uppercase, number, symbol; strong from 3', () {
    expect(passwordStrength('basil'), 0);
    expect(passwordStrength('basilbasil'), 1);
    expect(passwordStrength('basilbasil1'), 2);
    expect(isStrongPassword(passwordStrength('basilbasil1')), isFalse);
    expect(passwordStrength('basilbasil1!'), 3);
    expect(isStrongPassword(passwordStrength('basilbasil1!')), isTrue);
    expect(passwordStrength('Basilbasil1!'), 4);
  });
}
